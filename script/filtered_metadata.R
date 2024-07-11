#!/usr/bin/env R
library(tidyverse)
library(data.table)

#your work dir 
setwd("/Your_dir")

##########args##########
#input
download.date <- as.Date("2023-11-30") #The last day of the period to be analyzed
country.info.name <- "common/country_info.txt"
metadata.name <- "input/metadata.tsv"

##########parameters##########
#period to be analyzed
day.delay <- 0
day.analyzed <- 150

date.end <- download.date - day.delay
date.start <- date.end - day.analyzed + 1

country.interest.v <- c('USA','United Kingdom', 'Japan', 'South Africa', 'Denmark')


##########data preprocessing & QC##########
#read input country info
country.info <- read.table(country.info.name,header=T,sep="\t",quote="")
country.info <- country.info %>% select(-region)

#read input metadata
metadata <- fread(metadata.name,header=T,sep="\t",quote="",check.names=T)
#filtering
metadata.filtered <- metadata %>%
                       distinct(strain,.keep_all=T) %>%
                       filter(host == "Homo sapiens",
                              str_length(date) == 10,
                              pango_lineage != "",
                              pango_lineage != "None",
                              pango_lineage != "?")

                              
#converting an object to a date
metadata.filtered <- metadata.filtered %>%
                       mutate(date = as.Date(date))

#merge country name and country info
metadata.filtered <- merge(metadata.filtered,country.info,by="country")
metadata.filtered <- metadata.filtered %>% mutate(region_analyzed = ifelse(country %in% country.interest.v,
                                                                           as.character(country),
                                                                           as.character(sub_region)))

#filter the period of analysis
metadata.filtered.analyzed <- metadata.filtered %>% filter(date >= date.start, date <= date.end)

#region of interest
region.interest <- "USA"
#filter region
metadata.filtered.analyzed.region <- metadata.filtered.analyzed %>% filter(region_analyzed == region.interest)
#write output
write.table(metadata.filtered.analyzed.region,"input/metadata_filtered_USA_230701_231130.txt",col.names=T,row.names=F,sep="\t",quote=F)
