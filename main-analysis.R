## load the data
masterdf = readRDS("data/masterdf.rds")

## load the packages
library(plyr)
library(ggplot2)
library(FNN)
library(rpart)
library(igraph)


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
tmp = subset(masterdf, select = c("unitid",
                                  "apps7",
                                  "apps12",
                                  "app_delta",
                                  "app_delta_pct",
                                  "yrate_delta"))
tmp = arrange(tmp, desc(app_delta_pct))
head(tmp, 25)
rm(tmp)

## lets create a scatterplot that approximates the S&K post
g = ggplot(masterdf, aes(app_delta_pct, yrate_delta)) 
g = g + geom_point(alpha=.55)
g = g + xlab('% Change in Apps 2007 - 2012') + ylab('PP Change in Yield Rate')
g = g + xlim(-7, 7) + ylim(-1, 1)
g = g + geom_hline(aes(colour="red", yintercept=median(yrate_delta)))
g = g + geom_vline(aes(colour="red", xintercept=median(app_delta_pct)))
g = g + geom_text(data=NULL, x=4.5, y = -.9, label="Apps Up, Yield Down")
g = g + geom_text(data=NULL, x=4.5, y = .9, label="Apps Up, YIeld Up")
g = g + geom_text(data=NULL, x=-4.5, y = .9, label="Apps Down, Yield Up")
g = g + geom_text(data=NULL, x=-4.5, y = -.9, label="Apps Down, Yield Down")
g
ggsave(file="figure/scatter.png")

## assign the segments from the scatterplot
masterdf$segment = NA
masterdf$segment[masterdf$app_delta_pct >= median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta >= median(masterdf$yrate_delta)] = 'Apps Up / Yield Up'
masterdf$segment[masterdf$app_delta_pct >= median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta < median(masterdf$yrate_delta)] = 'Apps Up / Yield Down'
masterdf$segment[masterdf$app_delta_pct < median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta >= median(masterdf$yrate_delta)] = 'Apps Down / Yield Up'
masterdf$segment[masterdf$app_delta_pct < median(masterdf$app_delta_pct) &
                   masterdf$yrate_delta < median(masterdf$yrate_delta)] = 'Apps Down / Yield Down'
saveRDS(masterdf, file="data/masterdf.rds")

## lets look at the breakdown by the simple segments
(tab.basic = with(masterdf, table(segment)))
(tab.sector = with(masterdf, table(segment, sector)))
prop.table(tab.sector, 2)



#==============================================================================
## Dive A little Deeper - Basic Regression on Change relative to
## Sector, region, and 
#==============================================================================


# with(masterdf, table(sector))
# with(masterdf, table(obereg))
# with(masterdf, table(hloffer))
# with(masterdf, table(carnegie))
# 
# TODO: either group or not include some of the variables

## app change
f1 = formula(app_delta_pct ~ factor(sector) + factor(obereg))
ols.apps = lm(f1, data=masterdf)
summary(ols.apps)

## yield change
f2 = formula(yrate_delta ~ app_delta_pct + factor(sector) + factor(obereg))
ols.yield = lm(f2, data=masterdf)
summary(ols.yield)

## add on the predicted values and calc residuals
masterdf = mutate(masterdf,
                  pred_ols_apps = predict(ols.apps, masterdf),
                  ols_apps_resid = pred_ols_apps - app_delta_pct,
                  pred_ols_yrate = predict(ols.yield, masterdf),
                  ols_yield_resid = pred_ols_yrate - yrate_delta)

## plot the data -- if you want to study residuals
plot(masterdf$ols_apps_resid, masterdf$ols_yield_resid, type="p")


#==============================================================================
## KNN - Predict Yield rate pp change
#==============================================================================

## reshape  data to include the cols we want to decide how neighobors are found\\
knn.x = subset(masterdf, 
                  select = c('sector', 'obereg', 'app_delta_pct'))
knn.y = masterdf$yrate_delta

## use KNN regression from FNN package - submit train/test as same datasets
## not ideal, but I want the predictions for all cases
knn.mod = knn(knn.x,
              knn.x,
              knn.y,
              k=5)

## convert it back to a numeric value
knn.pred = as.numeric(as.character(knn.mod))

## put onto the masterdf
masterdf$knn.pred = knn.pred



#==============================================================================
## KNN - Lat/long (same sector)
#==============================================================================

## KNN regression, but only use lat/long
knn.x = subset(masterdf,
               select =c('latitude', 'longitud'))

## predict against
knn.mod2 = knn(knn.x,
               knn.x,
               knn.y,
               k=5)

## convert it back to a numeric value
knn.pred2 = as.numeric(as.character(knn.mod2))

## put the predictions back on
masterdf$knn.latlong.pred = knn.pred2


#==============================================================================
## Decision Tree
#==============================================================================

## Decision Tree - use to find nonlinear segmentation rules
keep = c("yrate_delta", "sector", "obereg" )
mod.df = masterdf[, keep]
rm(keep)

## fit the regression tree
tree = rpart(yrate_delta ~ sector +  obereg, 
             mod.df, 
             control = rpart.control(minsplit = 30, 
                                     minbucket = 15,
                                     cp = .001),
             method = "anova")
plot(tree); text(tree);


## predict the values -- generic based on segments, not exactly tailored
tree.pred = predict(tree, masterdf, type="vector")

## assign to the dataset
masterdf$tree.pred = tree.pred

#==============================================================================
## Network Data - Experimental Idea - Leverage a network graph relationships
## Idea: leverage relationships scraped from "Similar Colleges" on various
##       college search websites
#==============================================================================

## load the data - loads two data frames, connections btween schools and 
## some meta data -- dont need metadata
load("~/Dropbox/GitHub/SearchNetwork/edges-schools.rdata")
rm(schools)

## fix the edges
edges$from = as.numeric(edges$from)
edges$to = as.numeric(edges$to)

## keep only the connections for schools in masterdf
edges.f = subset(edges, from %in% masterdf$unitid & to %in% masterdf$unitid)

## is every school there
ef.l = length(unique(edges.f$from))
et.l = length(unique(edges.f$to))
ef.l == nrow(masterdf)
et.l == nrow(masterdf)
## NO: not onlys schools are there -- keep in mind

## put the data into a network - directed graph
net = graph.data.frame(edges.f, directed=TRUE)

## quick plot to show one visual representation of the data we have
png(filename="figure/network.png")
plot(net, 
     layout = layout.fruchterman.reingold,
     vertex.size=4,
     vertex.label = NA,
     edge.arrow.mode = 0)
dev.off()

## prediction method:  for school x, simple average for all schools that list
##                     school X as a similar college.
## alt pred idea:    for school X, use only the schools that are listed on
##                     school X's profile.
## NOTE: this is a slow loop but intentinally easier to debug and understand
## Admission: using igraph is prob overkill below, but opens up ideas for
## leveraging a graph's properties for deeper mining

## create an empty vector we will populate -- helps get around schools not in graph
## You prob want to store more data, like how many schools, se mean, etc.
nx_pred = data.frame(stringsAsFactors=F)
for (S in masterdf$unitid) {
 cat("starting school ", S, "\n")
 # get the vertex id in the network for the school of interest
 idx = which(V(net)$name==S)
 # get the schools that have school X listed as a "Similar" College
 idx.nei = neighbors(net, v=idx, mode="in")
 # get the unitids
 comps = V(net)$name[idx.nei]
 comps = as.numeric(comps)
 # subset the main data so we can calc the mean, which is our prediction
 tmp =  subset(masterdf, unitid %in% comps)
 # here's our prediction
 tmp.pred = mean(tmp$yrate_delta)
 # put the prediction into a dataframe and append it to our holder
 tmp.pred = data.frame(unitid = S,
                       nx_pred = tmp.pred)
 nx_pred = rbind.fill(nx_pred, tmp.pred)
 # status message
 cat("finished school: ", S, "\n")
}

## join the data -- same order is implied, be careful!!
masterdf$nx_pred = nx_pred$nx_pred


#==============================================================================
## Compare the prediction methods
## Going to use MAE = https://www.kaggle.com/wiki/MeanAbsoluteError
#==============================================================================

## using the ROCR package to get AUC value for each prediction
pred.df = subset(masterdf,
                 select = c("yrate_delta", 
                            "pred_ols_yrate",
                            "knn.pred",
                            "knn.latlong.pred",
                            "tree.pred",
                            "nx_pred"))

## for each column, calc the AUC
metrics = data.frame(stringsAsFactors=F)
MODS = colnames(pred.df)[2:ncol(pred.df)]
for (MOD in MODS) {
 y = pred.df[,1]
 x = pred.df[,MOD]
 # calc error
 e = y - x
 # calc MAE
 ae = abs(e)
 mae = mean(ae, na.rm=TRUE)
 # calc RMSE
 se = e^2
 mse = mean(se, na.rm=T)
 rmse = sqrt(mse)
 # make the df
 tmp.df = data.frame(model = MOD,
                     mae = mae,
                     rmse = rmse)
 metrics = rbind.fill(metrics, tmp.df)
}


## print out the results
metrics

## plot results
plot(metrics$model, metrics$mae, 
     ylim=c(0,.2),
     xlab = "Model",
     ylab = "Mean Absolute Error (MAE)",
     main = "MAE for each Model \nPredict Yield Rate PP Change 2007 - 2011")

plot(metrics$model, metrics$rmse, 
     #ylim=c(0,.2),
     xlab = "Model",
     ylab = "RMSE",
     main = "RMSE for each Model \nPredict Yield Rate PP Change 2007 - 2011")




