###############################################################################
## Analyze the impact of app growth on yield
## Goal: mimic S&K post but add value to it by providing code on how to 
##       run this on your own
##
## @BrockTibert
###############################################################################

## set the working directory for the project
setwd("~/Dropbox/Projects/sk-delta-apps-yield")

## create a directory to hold the IPDS data we download
dir.create("raw", showWarnings=FALSE)

## load the libraries
library(plyr)
library(reshape2)
library(ggplot2)
library(stringr)

#==============================================================================
## Collect the data
#==============================================================================

## Build the variables we need to crawl the data
YEARS = c(2007, 2012)

## loop and get the IC datasets
BASE = "http://nces.ed.gov/ipeds/datacenter/data/IC"
## For each survey, grab the data
for (Y in YEARS) {
  URL = paste0(BASE, Y, ".zip")
  fname = paste0("ic", Y, ".zip")
  download.file(url = URL, 
                destfile = paste0("raw/", fname))
}

## get the directory information so we can attach type of school, etc.
BASE = "http://nces.ed.gov/ipeds/datacenter/data/HD"
for (Y in YEARS) {
  URL = paste0(BASE, Y, ".zip")
  fname = paste0("hd", Y, ".zip")
  download.file(url = URL, 
                destfile = paste0("raw/", fname))
}

## unzip the files
FILES = list.files("raw", full.names=TRUE)
for (FILE in FILES)  {
  unzip(FILE, exdir = "raw/")
}


#==============================================================================
## Parse the data into 1 large dataset
#==============================================================================

## parse the IC datasets into 1 dataframe
FILES = list.files("raw", 
                   pattern = "ic.*\\.csv",
                   full.names=TRUE)
ic = data.frame(stringsAsFactors=FALSE)
for (FILE in FILES)  {
  tmp = read.table(FILE, 
                   sep=",", 
                   header = TRUE, 
                   stringsAsFactors=F)
  # fix the colnames to lowercase
  colnames(tmp) = tolower(colnames(tmp))
  # extract the year from the filename -- example of regex to parse date
  yr = str_extract(FILE, "20[0-9]{2}")
  tmp$year = yr
  ic = rbind.fill(ic, tmp)
}

dim(ic)
colnames(ic)

## parse the hd datasets
FILES = list.files("raw", 
                   pattern = "hd.*\\.csv",
                   full.names=TRUE)
hd = data.frame(stringsAsFactors=FALSE)
for (FILE in FILES)  {
  tmp = read.table(FILE, 
                   sep=",", 
                   header = TRUE, 
                   stringsAsFactors=F)
  # fix the colnames to lowercase
  colnames(tmp) = tolower(colnames(tmp))
  # extract the year from the filename -- example of regex to parse date
  yr = str_extract(FILE, "20[0-9]{2}")
  tmp$year = yr
  hd = rbind.fill(hd, tmp)
}

dim(hd)
colnames(hd)

## merge the datasets -- inner join
df = merge(hd, 
           ic, 
           by.x = c("unitid", "year"), 
           by.y = c("unitid", "year"))

## cleanup
rm(tmp, hd, ic, FILE, FILES, yr)


#==============================================================================
## Process the data
#==============================================================================

## subset to be current year data, pub/priv 4years, and deggree granting
df.f = subset(df, appdate == 2 & 
                sector %in% c(1,2) & 
                deggrant == 1 & 
                obereg %in% c(1:8))

## keep only schools with 1K apps or more (in survey year)
df.f$applcn = as.numeric(df.f$applcn)
df.f = subset(df.f, applcn >= 1000)

## keep schools that reported 2007 and 2012 data IN THE SURVEY YEAR
## I am shocked at how many schools are not capable/willing to do this
schools = ddply(df.f, .(unitid), summarise, recs = length(unitid))
schools = subset(schools, recs == 2)
schools = subset(df.f, unitid %in% schools$unitid)

## calc yield rate 
schools$enrlt = as.numeric(schools$enrlt)
schools$admssn = as.numeric(schools$admssn)
schools = mutate(schools,
                 yrate = enrlt/admssn)

## keep the basic school info from the 2012 survey
masterdf = subset(schools,
                  subset = year == 2012,
                  select = c('unitid', 'instnm', 'sector', 
                             'obereg', 'stabbr', 'hloffer',
                             'carnegie', 'longitud', 'latitude'))

## now reshape the data so 1 row per school
apps = dcast(schools, unitid ~ year, value.var="applcn")
names(apps)[2] = "apps7"
names(apps)[3] = "apps12"
admits = dcast(schools, unitid ~ year, value.var="admssn")
names(admits)[2] = "admits7"
names(admits)[3] = "admits12"
enroll = dcast(schools, unitid ~ year, value.var="enrlt")
names(enroll)[2] = "enroll7"
names(enroll)[3] = "enroll12"
yrate = dcast(schools, unitid ~ year, value.var="yrate")
names(yrate)[2] = "yrate7"
names(yrate)[3] = "yrate12"

## bind the data - uses same variable, in this case, unitid
masterdf = merge(masterdf, apps)
masterdf = merge(masterdf, admits)
masterdf = merge(masterdf, enroll)
masterdf = merge(masterdf, yrate)

## finally, calc change metrics
masterdf = mutate(masterdf,
                  app_delta = apps12 - apps7,
                  app_delta_pct = app_delta / apps7,
                  yrate_delta = yrate12 - yrate7)

## save out the file
saveRDS(masterdf, file="data/masterdf.rds")

#==============================================================================
## Basic Analysis
#==============================================================================

## compare  distributions of  app change, % change apps, pp change in yield
png(filename="figure/distributions.png")
par(mfrow=c(1, 3))
with(masterdf, 
     hist(app_delta, 
          ylab="", 
          xlab="", 
          main="Change in App Volume \n2007 - 2012"))
with(masterdf, 
     hist(app_delta_pct, 
          ylab="", 
          xlab="", 
          main="% Change in App Volume \n2007 - 2012"))
with(masterdf, 
     hist(yrate_delta, 
          ylab="", 
          xlab="", 
          main="Change in Yield Rate (PP) \n2007 - 2012"))
dev.off()

## summary stats
summary(masterdf[,c("app_delta", 
                    "app_delta_pct" ,
                    "yrate_delta")])

## who are the outliers with massively large growth
tmp = subset(masterdf, select = c("instnm",
                                  "apps7",
                                  "apps12",
                                  "app_delta",
                                  "app_delta_pct",
                                  "yrate_delta"))
tmp = arrange(tmp, desc(app_delta_pct))
head(tmp, 25)
rm(tmp)

## lets create a scatterplot that approximates the S&K post
par(mfrow=c(1,1))
g = ggplot(masterdf, aes(app_delta_pct, yrate_delta)) 
g = g + geom_point(alpha=.55)
g = g + xlab('% Change in Apps 2007 - 2012') + ylab('PP Change in Yield Rate')
g = g + xlim(-7, 7) + ylim(-1, 1)
g = g + geom_hline(aes(colour="red", yintercept=median(yrate_delta)))
g = g + geom_vline(aes(colour="red", xintercept=median(app_delta_pct)))
g = g + geom_text(data=NULL, x=4.5, y = -.9, label="App Growth, Drop Yield")
g = g + geom_text(data=NULL, x=4.5, y = .9, label="App Growth, Increase Yield")
g = g + geom_text(data=NULL, x=-4.5, y = .9, label="App Decline, Increase Yield")
g = g + geom_text(data=NULL, x=-4.5, y = -.9, label="App Decline, Drop Yield")
g
ggsave(file="figure/scatter.png")

## assign the segments from the scatterplot
masterdf$segment = NA
masterdf$segment[masterdf$app_delta_pct >= median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta >= median(masterdf$yrate_delta)] = 'High App / High Yield'
masterdf$segment[masterdf$app_delta_pct >= median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta < median(masterdf$yrate_delta)] = 'High App / Low Yield'
masterdf$segment[masterdf$app_delta_pct < median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta >= median(masterdf$yrate_delta)] = 'Low App / High Yield'
masterdf$segment[masterdf$app_delta_pct < median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta < median(masterdf$yrate_delta)] = 'Low App / Low Yield'
saveRDS(masterdf, file="data/masterdf.rds")

## lets look at the breakdown by the simple segments
(tab.basic = with(masterdf, table(segment)))
(tab.sector = with(masterdf, table(segment, sector)))



#==============================================================================
## Dive A little Deeper
#==============================================================================

## Decision Tree - use to find nonlinear segmentation rules
keep = c("yrate_delta", "sector", "obereg", )
mod.df = masterdf[, keep]
mod.df = masterdf[, !(names(masterdf) %in% drops)]
rm(drops)
library(rpart)
tree = rpart(yrate_delta ~ ., 
             mod.df, 
             control = rpart.control(minsplit = 50, 
                                     minbucket = 20))
plot(tree); text(tree);

TODO: remove states and other high dimension data
TODO: logistic regression for probability statements (use 2007 to explain 2012 with demos)
TODO: mars model
TODO: look at changes by sector, carnegie, and state/region
TODO: can we use CAPPEX/sna data to help explain variance in value?
TODO: get the data off of the servers


#==============================================================================
## Use the Network Data
#==============================================================================
