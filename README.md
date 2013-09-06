Code to Follow Along with S&K Post
===================

Code to replicate the [Scannel and Kurz Post](http://www.scannellkurz.com/blog/increasing_applicant_pool_monday_musings) on 
why huge swings in app growth might not always be good for Enrollment Managers.

One important note.  I have no affiliation with S&K.  I simply wanted to build upon a common idea and produce code so others can run and build upon this very important concept in Enrollment Management.

## About

I have been collecting and analyzing data along the lines of the S&K and post for a while now, but they beat me to the punch and did a great job highlighting an important point.

With that said, I figured it would be nice to demonstrate how you could replicate (or modify) this type of analysis yourself,
for *FREE* , using [R](http://cran.r-project.org/) and [IPEDS](http://nces.ed.gov/ipeds/datacenter/).  

This repo contains all of my R code that:

1. Downloads the necessary files from IPEDS
2. Clean, merge the files
3. Create a master dataset that we use to profile and generate models

Unlike the S&K post, I am going to do two things:

1. Demostrate documented code
2. Build a few models to try to help explain the changes in yield relative to a few factors.

To follow along, run the contents of the `college-clean.r` to build and save a dataframe (dataset) and then walk through the `main-analysis.r` file.  I attempted to comment as much as possible in case you are like me and learn by example.

I do not intend for this repo to be viewed as a comprehensive analysis with specific conclusions, but more of a tutorial
on how analysts in EM might be able to conduct similar studies themselves without requiring expensive software.

## Analysis

I won't go too in-depth with re-blogging the concepts that S&K has already done well, but basically this in an important topic that Enrollment Managers need to start thinking about.  Here are my two cents.  Tactics like waiving app fees, Fast Apps, apps that only require a name, etc., will *probably* have disastrous effects on your yield planning.  In my opinion, stabilzing (and obviously improving yield) is THE main goal year to year; everything else is just noise.  Therefore, if you play games and introduce more variance in yield, your May 1 will become alot more stressful.

Rant aside, lets dive into some output.  There are a few differences that I want to list up front:

- Instead of looking at 1 year, I looked at changes in applications and yield from 2007 to 2012
- To be included in the anslysis, a school had to report data in both years.  All other schools were excluded.
- This resulted in 742 Public 4-year  (Sector = 1) and Private 4-year (Sector = 2) schools

First, lets look at the distributions for the values we want to study:

![Distributions](https://raw.github.com/Btibert3/sk-delta-apps-yield/master/figure/distributions.png)

By and large, the values are pretty well distributed.  We will be using some techniques that ignore the normality assumption (like we do most times anyway), but it's always nice to see distributions that are wildly skewed.

Below is a scattergraph that is similar, but not exactly the same, as the one in the post. Because this looks at a larger timeframe, the variance is much larger than what you see in the original post.

![Scatter](https://raw.github.com/Btibert3/sk-delta-apps-yield/master/figure/scatter.png)

The plot is similar in that we see a downward trend; larger app increases over 5 years tended to experience large drops in yield rates.  

I segment the plot by median values.  Here are how the schools are distributed by sector.  The value is a column % within each sector, with 1 = Public 4-year, 2 = Private 4-year.

![Xtab](https://raw.github.com/Btibert3/sk-delta-apps-yield/master/figure/segments-sector-xtab.PNG)

From the table above, about 1/3rd of both Public and Private schools saw apps go up, but yield drop.


## Modeling

Going a step beyond the S&K post, I wanted to try to fit some relatively basic models to the data to see if we could reasonably predict the change in 5-year yield rate.  For this, I chose only a few predictor variables; sector, school region, and 5-year % change in apps. I was more concerned with showing you how easy it is to code up your analytical ideas within R.

The techniques I chose were:
- OLS Multiple Regression
- Regression Tree
- K-Nearest Neighbor (5) 
- K-Neareet Neightbor (5) but using a school's Lat/Long data to define neighbors
- A Network Graph Approach (more on this later)

I am using Mean Absolute Error (MAE) and Root Mean Squared Error (RMSE) to evaluate model performance.  These are two of the commonly used merics listed on [Kaggle's](https://www.kaggle.com/wiki/Metrics) website.

Because the OLS approach performed best overall, I wanted to plot the residuals from models that predict the 5-year app change and 5-year yield rate change.  This plot might be useful if you wanted to look at schools that performed way better or worse than would have been expected in either 1 or both models.

### Network Graph Approach

At the moment, I am mildly obsessed with looking at problems as a problem that can be solved be leveraging a graph structure.  Common examples are Netflix and Facebook.  In this post, I am showcasing an idea I have had forever now.  I scraped the data for "Similar Colleges" found on various College Search websites.  A connection between two schools is formed when School A lists School B as a "Similar College" on their profile.  My thought is that we can leverage these types of connections to better understand market position, and in turn, yearly changes in our performance metrics.

For this post, I filtered the graph to only include the 742 schools we have been using.  Surprisingly, not all of the schools were in my network dataset, but that is a problem for another day.  Graphs can be visualized using a number of algorithms, but below is a basic picture of how our schools are related.

![network](https://raw.github.com/Btibert3/sk-delta-apps-yield/master/figure/network.png)

I know it looks like a big hairball, but I do love how easy it is to see how schools cluster together.  

Quick aside, I hypothesize that these clusters of schools represent an institution's competitive market.  While it could be the case, I believe too often we assume our market is based primarily on geographic market.  I believe studying this network structure will help us find new strategic markets, identify areas of opportunity, etc when recruiting and planning travel.

To predict school X's 5-year change in yield, I simply average the 5-year change for all institutions that list School X on their profile page.  Using this approach might be extreme overkill, but it helped me think through a number of issues using the `igraph` package in R.

## Summary

The image belwo summarizes the performance for the 5 models.

![outcomes](https://raw.github.com/Btibert3/sk-delta-apps-yield/master/figure/performance.png)

Overall, the basic OLS regression the best, but not too far behind was the regression tree and the network-based similar colleges approach.  

The out-of-the-box K Nearest Neighbor performed poorly while the network-based model performed relatively well.  Intuitively this should make some sense, as institutions should be grouped on their percieved peer set, not statistically similarities.  I have to admit, I was surprised that geo-based neighbor approach didn't do better than it did.


