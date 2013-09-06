sk-delta-apps-yield
===================

Code to replicate the [Scannel and Kurz Post](http://www.scannellkurz.com/blog/increasing_applicant_pool_monday_musings) on 
why huge swings in app growth might not always be good for Enrollment Managers.

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



