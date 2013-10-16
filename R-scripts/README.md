# R-scripts for analyzing Coursera data

These scripts are written in R+Markdown ([knitr](http://yihui.name/knitr/)) format. It's easiest to open them in [RStudio](http://www.rstudio.com/), which has built-in support for this format. You can execute individual code-blocks with `Alt+Cmd C`, run all blocks, or "Knit HTML". 

## language_forum.Rmd
This file reads in the posts and comments from one or a number of courses, and uses the [Compact Language Detection Library package](http://cran.r-project.org/web/packages/cldr/index.html) to automatically recognize the language of forum posts. When we only look at posts over a certain length, it has proven to be quite accurage for most languages. You end up with a data.table with posts and comments, tagged by which course they came from, and which language is used. 

![](http://reganmian.net/images/indonesia-wordcloud-coursera.png)

## url_forum.Rmd
Extracts linked URLs from forum posts, ending up with a data.table that has a list of URLs and domains, linked back to the post table (with student IDs, course info etc). Shows summary statistic, including most linked URLs, most linked domains, and number of unique URLs per domain. 