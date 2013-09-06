Change in Applications and Yield
========================================================

## Overview
Today (8/26) Scannel and Kurz posted something that I have been been thinking about for some time now.  I have done similar analyses (not posted) in the past, so I wanted to share some code for those of in #emchat that think about data and don't want to use (or hace access to) expensive software like SPSS or SAS.  There is a rather steep learning curve to `R`, but chances are, you already have some people in your division that have some stats/programming experience.

## About this post
Use `R` to grab the IPEDS data we need and build a dataset to evaluate the changes in applications and yield rates between 2007 and 2012.  Unlike the S&K post, I want to look at a larger timeline to eliminate erratic chagnes from year to year.  

## About the data
I love IPEDS data, but there are quite a few critcisms about the data. Please oblige my rant given the technology we have today:

- It takes us way to long to report data and for it to be released
- Why does it take way too long for us to report Fiscal year data?
- Why dont we ask for more detailed information about application data
- why not ask about how much we spend on recruitment and marketing

## Get the data

Let's setup our R environment:


```r
## set the working directory for the project
setwd("~/Dropbox/Projects/sk-delta-apps-yield")
## create a directory to hold the IPDS data we download
dir.create("raw", showWarnings = FALSE)
## load the libraries
library(plyr)
library(reshape2)
library(ggplot2)
library(stringr)
```


Now lets grab the data.  If you visit the TODO: Ipeds data site, you will notice a common naming pattern for the data files.  We can use this structure to tell R to download the files onto a system.  No manually clicking!


```r
## Build the variables we need to crawl the data
YEARS = c(2007, 2012)
BASE = "http://nces.ed.gov/ipeds/datacenter/data/IC"
## For each survey, grab the data
for (Y in YEARS) {
    URL = paste0(BASE, Y, ".zip")
    fname = paste0("ic", Y, ".zip")
    download.file(url = URL, destfile = paste0("raw/", fname))
}
## get the directory information -- attach type of school, etc.
BASE = "http://nces.ed.gov/ipeds/datacenter/data/HD"
for (Y in YEARS) {
    URL = paste0(BASE, Y, ".zip")
    fname = paste0("hd", Y, ".zip")
    download.file(url = URL, destfile = paste0("raw/", fname))
}
```


Now we need parse the zip files and keep the contents in the `raw` directory.


```r
FILES = list.files("raw", full.names = TRUE)
for (FILE in FILES) {
    unzip(FILE, exdir = "raw/")
}
```

```
## Warning: error 1 in extracting from zip file Warning: error 1 in
## extracting from zip file Warning: error 1 in extracting from zip file
## Warning: error 1 in extracting from zip file
```



## Build the dataset

Now that we have the two CSV files, we need to bring them into `R`.  The key is that we want to think about how to shape and reshape the data. For this, we are going to bring in each file and stack them, meaning 1 set of rows for each survey year.  The trick here is that you need to be aware that some columns **may** be in one year and not another.  To get around this in R, we use the `rbind.fill` command from the `plyr` package.  Basically, this stacks the datasets and add variables automagically when one dataset has a columns not present in another.  Trust me, this function will save you more often than you could ever imagine.


```r
## parse the IC datasets into 1 dataframe
FILES = list.files("raw", pattern = "ic.*\\.csv", full.names = TRUE)
ic = data.frame(stringsAsFactors = FALSE)
for (FILE in FILES) {
    tmp = read.table(FILE, sep = ",", header = TRUE, stringsAsFactors = F)
    # fix the colnames to lowercase
    colnames(tmp) = tolower(colnames(tmp))
    # extract the year from the filename -- example of regex to parse date
    yr = str_extract(FILE, "20[0-9]{2}")
    tmp$year = yr
    ic = rbind.fill(ic, tmp)
}

## parse the hd datasets
FILES = list.files("raw", pattern = "hd.*\\.csv", full.names = TRUE)
hd = data.frame(stringsAsFactors = FALSE)
for (FILE in FILES) {
    tmp = read.table(FILE, sep = ",", header = TRUE, stringsAsFactors = F)
    # fix the colnames to lowercase
    colnames(tmp) = tolower(colnames(tmp))
    # extract the year from the filename -- example of regex to parse date
    yr = str_extract(FILE, "20[0-9]{2}")
    tmp$year = yr
    hd = rbind.fill(hd, tmp)
}
```


Let's see what we have.


```r
dim(ic)
```

```
## [1] 14553   190
```

```r
colnames(ic)
```

```
##   [1] "unitid"   "peo1istr" "peo2istr" "peo3istr" "peo4istr" "peo5istr"
##   [7] "peo6istr" "cntlaffi" "pubprime" "pubsecon" "relaffil" "level1"  
##  [13] "level2"   "level3"   "level4"   "level5"   "level6"   "level7"  
##  [19] "level8"   "level9"   "level10"  "level11"  "level12"  "openadmp"
##  [25] "admcon1"  "admcon2"  "admcon3"  "admcon4"  "admcon5"  "admcon6" 
##  [31] "admcon7"  "admcon8"  "admcon9"  "appdate"  "xapplcnm" "applcnm" 
##  [37] "xapplcnw" "applcnw"  "xadmssnm" "admssnm"  "xadmssnw" "admssnw" 
##  [43] "xenrlftm" "enrlftm"  "xenrlftw" "enrlftw"  "xenrlptm" "enrlptm" 
##  [49] "xenrlptw" "enrlptw"  "satactdt" "xsatnum"  "satnum"   "xsatpct" 
##  [55] "satpct"   "xactnum"  "actnum"   "xactpct"  "actpct"   "xsatvr25"
##  [61] "satvr25"  "xsatvr75" "satvr75"  "xsatmt25" "satmt25"  "xsatmt75"
##  [67] "satmt75"  "xsatwr25" "satwr25"  "xsatwr75" "satwr75"  "xactcm25"
##  [73] "actcm25"  "xactcm75" "actcm75"  "xacten25" "acten25"  "xacten75"
##  [79] "acten75"  "xactmt25" "actmt25"  "xactmt75" "actmt75"  "credits1"
##  [85] "credits2" "credits3" "credits4" "slo3"     "slo5"     "slo51"   
##  [91] "slo52"    "slo53"    "slo6"     "slo7"     "slo8"     "slo81"   
##  [97] "slo82"    "slo83"    "slo9"     "yrscoll"  "stusrv1"  "stusrv2" 
## [103] "stusrv3"  "stusrv4"  "stusrv8"  "stusrv9"  "libfac"   "athassoc"
## [109] "assoc1"   "assoc2"   "assoc3"   "assoc4"   "assoc5"   "assoc6"  
## [115] "sport1"   "confno1"  "sport2"   "confno2"  "sport3"   "confno3" 
## [121] "sport4"   "confno4"  "pctpost"  "calsys"   "xappfeeu" "applfeeu"
## [127] "xappfeeg" "applfeeg" "xappfeep" "applfeep" "ft_ug"    "ft_ftug" 
## [133] "ft_gd"    "ft_fp"    "pt_ug"    "pt_ftug"  "pt_gd"    "pt_fp"   
## [139] "tuitvary" "room"     "xroomcap" "roomcap"  "board"    "xmealswk"
## [145] "mealswk"  "xroomamt" "roomamt"  "xbordamt" "boardamt" "xrmbdamt"
## [151] "rmbrdamt" "alloncam" "xenrlm"   "enrlm"    "xenrlw"   "enrlw"   
## [157] "xenrlt"   "enrlt"    "xapplcn"  "applcn"   "xadmssn"  "admssn"  
## [163] "xenrlft"  "enrlft"   "xenrlpt"  "enrlpt"   "year"     "level17" 
## [169] "level18"  "level19"  "xactwr25" "actwr25"  "xactwr75" "actwr75" 
## [175] "ftgdnidp" "ptgdnidp" "docpp"    "docppsp"  "tuitpl"   "tuitpl1" 
## [181] "tuitpl2"  "tuitpl3"  "tuitpl4"  "disab"    "xdisabpc" "disabpct"
## [187] "distnced" "dstnced1" "dstnced2" "dstnced3"
```

```r
dim(hd)
```

```
## [1] 14787    70
```

```r
colnames(hd)
```

```
##  [1] "unitid"   "instnm"   "addr"     "city"     "stabbr"   "zip"     
##  [7] "fips"     "obereg"   "chfnm"    "chftitle" "gentele"  "ein"     
## [13] "opeid"    "opeflag"  "webaddr"  "adminurl" "faidurl"  "applurl" 
## [19] "sector"   "iclevel"  "control"  "hloffer"  "ugoffer"  "groffer" 
## [25] "fpoffer"  "hdegoffr" "deggrant" "hbcu"     "hospital" "medical" 
## [31] "tribal"   "locale"   "openpubl" "act"      "newid"    "deathyr" 
## [37] "closedat" "cyactive" "postsec"  "pseflag"  "pset4flg" "rptmth"  
## [43] "ialias"   "instcat"  "ccbasic"  "ccipug"   "ccipgrad" "ccugprof"
## [49] "ccenrprf" "ccsizset" "carnegie" "tenursys" "landgrnt" "instsize"
## [55] "cbsa"     "cbsatype" "csa"      "necta"    "dfrcgid"  "year"    
## [61] "npricurl" "hdegofr1" "f1systyp" "f1sysnam" "faxtele"  "countycd"
## [67] "countynm" "cngdstcd" "longitud" "latitude"
```


Now we will merge the 2 surveys into a single master dataframe. We will only keep rows that match on unitid and year in both files.


```r
df = merge(hd, ic, by.x = c("unitid", "year"), by.y = c("unitid", "year"))
```


One thing we need to be **very** mindful of is the fact that some schools report year-old applications data.  For example, on the 2012 survey, they may actually report 2011 application data instead of 2012.  In this day and age, I don't understand why this still happens, but it does quite a bit.  Nonetheless, we need to keep records where the institutions reported current year info (2007 and 2012). To do this, we use the appdate variable and keep only those records where the value = 2. and are 4 year public/private not-for-profit schools.  Lastly, we will follow S&K's logic and keep only institutions that recieve more than 1K in apps per year.


```r
df.f = subset(df, appdate == 2 & sector %in% c(1, 2) & deggrant == 1)
df.f$applcn = as.numeric(df.f$applcn)
df.f = subset(df.f, applcn >= 1000)
```


How many schools are present in each year?


```r
with(df.f, table(year))
```

```
## year
## 2007 2012 
##  853  933
```


This is the first indication that some schools have date in 1 year and not the other.  Since we want to calculate the change between 2007 and 2012, we need to keep schools that have reported data in both years.  


```r
## look at how many times a school is in the dataset
schools = ddply(df.f, .(unitid), summarise, recs = length(unitid))
## keep only those that are in both years
schools = subset(schools, recs == 2)
## filter the dataset
schools = subset(df.f, unitid %in% schools$unitid)

```


Before we start to put the data into a useable format, let's calculate some basic admission metrics.


```r
schools$enrlt = as.numeric(schools$enrlt)
schools$admssn = as.numeric(schools$admssn)
schools = mutate(schools, yrate = enrlt/admssn)
```


Lastly, we need to reshape the data.  Basically, each school is two rows in our dataset, one for each year.  We need to get this into a more managenable format for data analysis, which is 1 row per school.  Luckily, reshaping data is easy using the `reshape2` package.  


```r
masterdf = subset(schools, subset = year == 2012, select = c("unitid", "instnm", 
    "sector", "obereg", "stabbr", "hloffer", "carnegie", "longitud", "latitude"))
apps = dcast(schools, unitid ~ year, value.var = "applcn")
names(apps)[2] = "apps7"
names(apps)[3] = "apps12"
admits = dcast(schools, unitid ~ year, value.var = "admssn")
names(admits)[2] = "admits7"
names(admits)[3] = "admits12"
enroll = dcast(schools, unitid ~ year, value.var = "enrlt")
names(enroll)[2] = "enroll7"
names(enroll)[3] = "enroll12"
yrate = dcast(schools, unitid ~ year, value.var = "yrate")
names(yrate)[2] = "yrate7"
names(yrate)[3] = "yrate12"
## bind the data - uses same variable, in this case, unitid
masterdf = merge(masterdf, apps)
masterdf = merge(masterdf, admits)
masterdf = merge(masterdf, enroll)
masterdf = merge(masterdf, yrate)
## finally, calc change metrics
masterdf = mutate(masterdf, app_delta = apps12 - apps7, app_delta_pct = app_delta/apps7, 
    yrate_delta = yrate12 - yrate7)
```


## Analyze the data

Now that we have done the hardest part by collecting and cleaning the data, let's have some fun.  First, lets take a peak at the distribution of the two key variables.


```r
par(mfrow = c(1, 3))
with(masterdf, hist(app_delta, ylab = "", xlab = "", main = "Change in App Volume \n2007 - 2012"))
with(masterdf, hist(app_delta_pct, ylab = "", xlab = "", main = "% Change in App Volume \n2007 - 2012"))
with(masterdf, hist(yrate_delta, ylab = "", xlab = "", main = "Change in Yield Rate (PP) \n2007 - 2012"))
```

![plot of chunk dist](figure/dist.png) 


And the summary stats....


```r
summary(masterdf[, c("app_delta", "app_delta_pct", "yrate_delta")])
```

```
##    app_delta     app_delta_pct     yrate_delta     
##  Min.   :-5246   Min.   :-0.659   Min.   :-0.7693  
##  1st Qu.:  173   1st Qu.: 0.055   1st Qu.:-0.0969  
##  Median :  753   Median : 0.257   Median :-0.0536  
##  Mean   : 1542   Mean   : 0.354   Mean   :-0.0630  
##  3rd Qu.: 1914   3rd Qu.: 0.512   3rd Qu.:-0.0161  
##  Max.   :23719   Max.   : 6.568   Max.   : 0.4097
```


We can see from the stats above that the averge % change over the time period is around 35%, but one school grew by more than 600%!  Below is the list of the top 25 schools by % growth in apps.


```r
tmp = subset(masterdf, select = c("instnm", "apps7", "apps12", "app_delta", 
    "app_delta_pct", "yrate_delta"))
tmp = arrange(tmp, desc(app_delta_pct))
head(tmp, 25)
```

```
##                                                   instnm apps7 apps12
## 1                       University of Mary Hardin-Baylor  1258   9521
## 2                            Oklahoma Baptist University  1068   4909
## 3                                Saint Xavier University  2297  10247
## 4                                    Bridgewater College  1537   6079
## 5                              University of the Pacific  5893  22972
## 6                                    Westminster College  1146   3764
## 7                                   Mary Baldwin College  1507   4909
## 8                        East Tennessee State University  2824   9088
## 9                                  North Park University  1452   4633
## 10                               Gardner-Webb University  1977   6177
## 11                                      Tougaloo College  1058   3261
## 12                          Concordia University-Chicago  1164   3524
## 13                                    Notre Dame College  1378   4161
## 14                                 High Point University  2546   7663
## 15 Massachusetts College of Pharmacy and Health Sciences  1652   4939
## 16                            Houston Baptist University  4005  11738
## 17                                   Westminster College  1368   3935
## 18               University of Colorado Colorado Springs  3111   8847
## 19                        California Lutheran University  2445   6759
## 20                               Lenoir-Rhyne University  1770   4800
## 21                      New York Institute of Technology  2420   6546
## 22                                    Dillard University  2831   7533
## 23                             Virginia Wesleyan College  1512   3879
## 24                                        Gordon College  1574   4007
## 25                                        Ferrum College  1270   3146
##    app_delta app_delta_pct yrate_delta
## 1       8263         6.568   -0.385683
## 2       3841         3.596   -0.224638
## 3       7950         3.461   -0.197665
## 4       4542         2.955   -0.178616
## 5      17079         2.898   -0.121746
## 6       2618         2.284   -0.266440
## 7       3402         2.257   -0.132282
## 8       6264         2.218   -0.495423
## 9       3181         2.191   -0.203548
## 10      4200         2.124   -0.206734
## 11      2203         2.082    0.001552
## 12      2360         2.027   -0.169429
## 13      2783         2.020   -0.104228
## 14      5117         2.010   -0.147747
## 15      3287         1.990   -0.105530
## 16      7733         1.931   -0.112707
## 17      2567         1.876   -0.183646
## 18      5736         1.844   -0.213506
## 19      4314         1.764   -0.080873
## 20      3030         1.712   -0.146166
## 21      4126         1.705   -0.167655
## 22      4702         1.661    0.029864
## 23      2367         1.565   -0.134875
## 24      2433         1.546   -0.118763
## 25      1876         1.477   -0.129362
```



Finally, lets create the scatter plot....


```r
par(mfrow = c(1, 1))
g = ggplot(masterdf, aes(app_delta_pct, yrate_delta))
```

```
## Error: could not find function "ggplot"
```

```r
g = g + geom_point(alpha = 0.55)
```

```
## Error: object 'g' not found
```

```r
g = g + xlab("% Change in Apps 2007 - 2012") + ylab("PP Change in Yield Rate")
```

```
## Error: object 'g' not found
```

```r
g = g + xlim(-7, 7) + ylim(-1, 1)
```

```
## Error: object 'g' not found
```

```r
g = g + geom_hline(aes(colour = "red", yintercept = median(yrate_delta)))
```

```
## Error: object 'g' not found
```

```r
g = g + geom_vline(aes(colour = "red", xintercept = median(app_delta_pct)))
```

```
## Error: object 'g' not found
```

```r
g = g + geom_text(data = NULL, x = 4.5, y = -0.9, label = "App Growth, Drop Yield")
```

```
## Error: object 'g' not found
```

```r
g = g + geom_text(data = NULL, x = 4.5, y = 0.9, label = "App Growth, Increase Yield")
```

```
## Error: object 'g' not found
```

```r
g = g + geom_text(data = NULL, x = -4.5, y = 0.9, label = "App Decline, Increase Yield")
```

```
## Error: object 'g' not found
```

```r
g = g + geom_text(data = NULL, x = -4.5, y = -0.9, label = "App Decline, Drop Yield")
```

```
## Error: object 'g' not found
```

```r
g
```

```
## Error: object 'g' not found
```


Because I am looking at a longer time horizon than the S&K post, the data look rather different.  We can see that the longer trend is that the majority of the schools ahd drops in yield.  Obviously it will be fun to look at these groups in segements.





```r
## overall segments
with(masterdf, table(segment))
```

```
## segment
## High App / High Yield  High App / Low Yield  Low App / High Yield 
##                   126                   253                   253 
##   Low App / Low Yield 
##                   125
```

```r

## table by sector and segments
with(masterdf, table(segment, sector))
```

```
##                        sector
## segment                   1   2
##   High App / High Yield  32  94
##   High App / Low Yield   79 174
##   Low App / High Yield   86 167
##   Low App / Low Yield    51  74
```






