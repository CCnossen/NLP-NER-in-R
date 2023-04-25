# Try-out to run NLP and Named Entity Recognition in R for a one-off analysis
# by: @CCnossen
# 21 January, 2020

# install required packages
#install.packages(c('XML', 'RCurl', 'rvest', 'NLP', 'openNLP', 'openNLPdata'))
#install.packages("openNLPmodels.en", repos = "http://datacube.wu.ac.at/", type = "source")

# load packages
library(XML)
library(RCurl)
library(rvest)
library(NLP)
library(openNLP)
library(openNLPdata)

# remove stuff which will be created later
rm(edges, vertices, edges_i)

#-----------------------------------------------------------------------
# scrape from the url
#-----------------------------------------------------------------------
url <- "https://www.icij.org/investigations/pandora-papers/global-investigation-tax-havens-offshore/" #dump your link here

# create a trycatch block with error handling in an IF-statement reformatting the HTML appropriately on an error - OPTION 1
html <- tryCatch(getURL(url)
                ,warning = function(e) {html <- readLines(url)}
                ,error = function(e) {html <- readLines(url)}
                )

#Check if the data has content
if(length(html) > 1) {
  html <- paste(html, collapse = " ")
  html <- gsub("  ", "", html)
}

# get the outgoing links from the site
doc <- htmlParse(html)
links <- xpathSApply(doc, "//a/@href")
links <- as.data.frame(links)
links <- subset(links, substr(links, 1, 7) == 'http://' |  substr(links, 1, 8) == 'https://' )

# keep only links which are from the same domain
url_clean <- url
url_clean <- gsub("https://", "",url_clean)
url_clean <- gsub("http://", "",url_clean)
url_clean <- substr(url_clean, 1, regexpr('/', url_clean)[1]-1)
links <- as.data.frame(links[c(grep(url_clean, links$links)), ])

# remove social media noise
noise <- c('facebook', 'twitter', 'linkedin', 'instagram')
links <- links[-grep(paste(noise, collapse = "|"), links$links),]
links <- as.data.frame(links)



#clean all things inside HTML tags, and some general other cleaning 
html_cleaned <- gsub("<[^>]+>"," ",html)
html_cleaned <- gsub("\n"," ",html_cleaned)


#-----------------------------------------------------------------------
# Initiate looping through links (automated scraping)
#-----------------------------------------------------------------------

#i <- 1

#-----------------------------------------------------------------------
# set-up the annotation of entities using OpenNLP package
#-----------------------------------------------------------------------

sent_annot <- Maxent_Sent_Token_Annotator()
word_annot <- Maxent_Word_Token_Annotator()

html_annotated <- annotate(html_cleaned, list(sent_annot, word_annot))
html_annotated_doc <- AnnotatedPlainTextDocument(html_cleaned, html_annotated)

person_entities <- Maxent_Entity_Annotator(kind = 'person')
organization_entities <- Maxent_Entity_Annotator(kind = 'organization')

pipeline <- list(sent_annot, word_annot, person_entities, organization_entities)

html_annotated <- annotate(html_cleaned, pipeline)
html_annotated_doc <- AnnotatedPlainTextDocument(html_cleaned, html_annotated)

#-----------------------------------------------------------------------
# extract the annotated entities with help of a loop
#-----------------------------------------------------------------------

x <- html_annotated_doc[2]
x <- as.data.frame(x)
x <- subset(x, annotation.type == 'entity')
x$annotation.features <- as.character(x$annotation.features)

entities <- data.frame(
              data = character()
              ,type = character()
              ,stringsAsFactors = F
              )

i <- 1
repeat {
  newline <- as.data.frame(substr(html_cleaned, x$annotation.start[i], x$annotation.end[i]))
  newline$type <- x$annotation.features[i]
  entities <- rbind(entities, newline)
  
  i <- i + 1
  if (i > nrow(x)) {
    break
  }
}

#cleanup stuff
colnames(entities) <- c('data', 'type')
entities <- unique(entities)
entities$type <- gsub('list\\(kind =', '', entities$type)
entities$type <- gsub('\")', '', entities$type)
entities$type <- gsub('"', '', entities$type)
entities$type <- gsub(' ', '', entities$type)
entities$source <- url

#-----------------------------------------------------------------------
# coerce into vertices and edges
#-----------------------------------------------------------------------
if (!exists("vertices")) {
  vertices <- entities 
} else {
  vertices <- rbind(vertices, entities)
}

edges_i <- merge(x = entities[, c('data')], y = entities[, c('data')], by = NULL)
colnames(edges_i) <- c('node_1', 'node_2')
edges_i <- subset(edges_i, node_1 != node_2)
edges_i$rel_type <- 'same source data'
edges_i$source <- url
  
if (!exists("edges")) {
  edges <- edges_i
} else {
    edges <- rbind(edges, edges_i)
}

#-----------------------------------------------------------------------
# save scraped links
#-----------------------------------------------------------------------
if (!exists("scraped")) {
  scraped <- data.frame(
              url = character()
              ,text = character()
              ,stringsAsFactors = F
              )
}

scraped[nrow(scraped)+1,] <- c(url, html)

#-----------------------------------------------------------------------
# iterate
#-----------------------------------------------------------------------

links_tobescraped <- links[-grep(paste(scraped$url, collapse = "|"), links$links),]
links_tobescraped <- as.data.frame(links_tobescraped)

#i <- i+1
#url <- links$links[i]











