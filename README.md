Code to Follow Along with S&K Post
===================

Code to replicate the [Scannel and Kurz Post](http://www.scannellkurz.com/blog/increasing_applicant_pool_monday_musings) on 
why huge swings in app growth might not always be good for Enrollment Managers.

One important note.  I have no affiliation with S&K.  I simply wanted to build upon a common idea and produce code so others can run and build upon this very important concept in Enrollment Management.

## About

I have been collecting and analyzing data along the lines of the S&K and post for a while now, but they beat me to the punch.
With that said, I figured it would be nice to demonstrate how you could replicate (or modify) this type of analysis yourself,
for *FREE* using [R](http://cran.r-project.org/) and [IPEDS](http://nces.ed.gov/ipeds/datacenter/).  This repo contains
all of my R code that:

1. Downloads the necessary files from IPEDS
2. Clean, merge the files
3. Create a master dataset that we use to profile and generate models

Unlike the S&K post, I am going to do two things:

1. Demostrate documented code
2. Build a few models to try to help explain the changes in yield relative to a few factors.

I do not intend for this repo to be viewed as a comprehensive analysis with specific conclusions, but more of a tutorial
on how analysts in EM might be able to conduct similar analyses themselves without needing expensive software.

## Analysis

I won't go too in-depth with re-blogging the concepts that S&K has already done well, but basically this in an important topic that Enrollment Managers need to start thinking about.  Here are my two cents.  Tactics like waiving app fees, Fast Apps, apps that only require a name, etc., can *potentially* have disastrous effects on your yield planning.  In my opinion, stabilzing (and obviously improving yield) is THE main goal year to year; everything else is just noise.  Therefore, if you play games and introduce more variance in yield, your May 1 will become alot more stressful.

Rant aside, lets dive into some output.  There are a few differences that I want to list:

- Instead of looking at 1 year, I looked at changes in application and yield from 2007 to 2012
- To be included in the anslysis, a school had to report data in both years.  All other schools were excluded.
- This resulted in 742 Public 4-year  (Sector = 1) and Private 4-year (Sector = 2) schools

Below is a scattergraph that is similar, but not exactly the same, as the one in the post. Because this looks at a larger timeframe, the variance is much larger than what you see in the original post.

!(Scatter)["figure/scatter.png"]
