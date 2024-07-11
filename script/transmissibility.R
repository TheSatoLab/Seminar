#!/usr/bin/env R
library(tidyverse)
library(data.table)
library(ggplot2)
library(rbin)
library(cmdstanr)
library(patchwork)
library(RColorBrewer)

#your work dir 
setwd("/Your_dir") 

#check your cmdstan dir
cmdstan_path() 

##########args##########
#input files
stan_f.name <- "script/multinomial_independent.ver2.stan"
metadata.name.usa <- "input/metadata_filtered_USA_230701_231130.txt"


#output dir and files
out.prefix <- "output/output"
pdf.observed.name <- paste(out.prefix,".method1.observed.pdf",sep="")
pdf.growth.rate.name <- paste(out.prefix,".method1.growth_rate.pdf",sep="")
txt.growth.rate.name <- paste(out.prefix,".method1.growth_rate.txt",sep="")
pdf.theta.name <- paste(out.prefix,".method1.theta.pdf",sep="")
pdf.theta.name_2 <- paste(out.prefix,".method1.theta.with_ref.pdf",sep="")


##########parameters##########
#general
core.num <- 4 #check your PC core num
variant.ref <- "HV.1" 

#period to be analyzed (150days)
date.end <- as.Date("2023-11-30")
date.start <- as.Date("2023-07-01")

#min numbers
limit.count.analyzed <- 50 

#Transmissibility
bin.size <- 1
generation_time <- 2.1

#compile model
multi_nomial_model <- cmdstan_model(stan_f.name)


##########transmissibility estimation##########

region.interest <- "USA"

#read input metadata
metadata.filtered.analyzed.region <- read.csv(metadata.name.usa,header=T,sep="\t",quote="",check.names=T)
metadata.filtered.analyzed.region <- metadata.filtered.analyzed.region %>% mutate(date = as.Date(date))
#count variant.ref
num.variant.ref <- metadata.filtered.analyzed.region %>% filter(pango_lineage == variant.ref) %>% nrow()

#count pango_lineage ,proportion and filtering
total.analyzed <- nrow(metadata.filtered.analyzed.region)
count.analyzed.region.df <- metadata.filtered.analyzed.region %>% group_by(pango_lineage) %>% summarize(count.analyzed = n(), prop.analyzed = count.analyzed / total.analyzed)
count.analyzed.region.df.filtered <- count.analyzed.region.df %>% filter(count.analyzed > limit.count.analyzed) %>% arrange(desc(count.analyzed))
  
#select intersting pango_lineage
variant.interest.v <- count.analyzed.region.df.filtered$pango_lineage %>% as.character()
  
#select intersting pango_lineage
metadata.filtered.analyzed.region.selected <- metadata.filtered.analyzed.region %>% filter(pango_lineage %in% variant.interest.v)
  
######Transmissibility
#convert date to num (add column date.bin.num)
metadata.filtered.interest <- metadata.filtered.analyzed.region.selected %>% mutate(date.num = as.numeric(date) - min(as.numeric(date))  + 1, date.bin = cut(date.num,seq(0,max(date.num),bin.size)), date.bin.num = as.numeric(date.bin))
metadata.filtered.interest <- metadata.filtered.interest %>% filter(!is.na(date.bin))

#count date.bin.num,pango_lineage
metadata.filtered.interest.bin <- metadata.filtered.interest %>% group_by(date.bin.num,pango_lineage) %>% summarize(count = n()) %>% ungroup()

#change from long type to wide type
metadata.filtered.interest.bin.spread <- metadata.filtered.interest.bin %>% spread(key=pango_lineage,value = count)
metadata.filtered.interest.bin.spread[is.na(metadata.filtered.interest.bin.spread)] <- 0

#create metadata to run stan

X <- as.matrix(data.frame(X0 = 1, X1 = metadata.filtered.interest.bin.spread$date.bin.num))
  
Y <- metadata.filtered.interest.bin.spread %>% select(- date.bin.num) %>% select(all_of(variant.interest.v))

#calculate the proportion of pango_lineage
count.group <- apply(Y,2,sum)
count.total <- sum(count.group)
prop.group <- count.group / count.total
  
Y <- Y %>% as.matrix()
  
group.df <- data.frame(group_Id = 1:ncol(Y), group = colnames(Y))
  
Y_sum.v <- apply(Y,1,sum)
  
data.stan <- list(K = ncol(Y),
                  N = nrow(Y),
                  D = 2,
                  X = X,
                  Y = Y,
                  generation_time = generation_time,
                  bin_size = bin.size,
                  Y_sum = Y_sum.v)
  
#run stan
fit.stan <- multi_nomial_model$sample(
  data=data.stan,
  iter_sampling=1000,
  iter_warmup=500,
  seed=1234,
  parallel_chains = 4,
  max_treedepth = 20,
  chains=core.num)
  
  
#growth rate
stat.info <- fit.stan$summary("growth_rate") %>% as.data.frame()
stat.info$Pango.lineage <- colnames(Y)[2:ncol(Y)]
  
stat.info.q <- fit.stan$summary("growth_rate", ~quantile(.x, probs = c(0.005,0.995))) %>% as.data.frame() %>% rename(q0.5 = `0.5%`, q99.5 = `99.5%`)
stat.info <- stat.info %>% inner_join(stat.info.q,by="variable")
  
stat.info <- stat.info %>% mutate(signif = ifelse(q0.5 > 1,'higher','not higher'))
stat.info <- stat.info %>% arrange(mean)
stat.info <- stat.info %>% mutate(Pango.lineage = factor(Pango.lineage,levels=Pango.lineage))
  
#write output
write.table(stat.info,txt.growth.rate.name,col.names=T,row.names=F,sep="\t",quote=F)
  
  
#filter the top 10 of mean
stat.info_10 <- stat.info %>% top_n(10,mean) %>% arrange(desc(mean))
  
#growth rate plot
  
ylabel <- paste('relative growth rate per generation (per ',variant.ref,')',sep="")
  
g <- ggplot(stat.info_10,aes(x=Pango.lineage,y=mean,fill=signif))
g <- g + geom_bar(stat = "identity")
g <- g + geom_errorbar(aes(ymin= q5, ymax = q95), width = 0.2)
g <- g + geom_hline(yintercept=1, linetype="dashed", alpha=0.5)
g <- g + theme_set(theme_classic(base_size = 12, base_family = "Helvetica"))
g <- g + theme(panel.grid.major = element_blank(),
               panel.grid.minor = element_blank(),
               panel.background = element_blank(),
               strip.text = element_text(size=8))
g <- g + theme_set(theme_classic(base_size = 12, base_family = "Helvetica"))
g <- g + theme(panel.grid.major = element_blank(),
               panel.grid.minor = element_blank(),
               panel.background = element_blank(),
               strip.text = element_text(size=8))
g <- g + coord_flip()
g <- g + scale_fill_manual(breaks=c("higher","not higher"),values=c("lightsalmon","gray70"))
g <- g + xlab('') + ylab(ylabel)
g <- g + ggtitle(region.interest)

g
  
#plot growth rate
pdf(pdf.growth.rate.name,width=5,height=6)
plot(g)
dev.off()
  
  

#theta

#create df from
data_Id.df <- data.frame(date_Id = X[,2], Y_sum = apply(as.data.frame(Y),1,sum), date = as.Date(X[,2],origin=date.start))

data.freq <- metadata.filtered.interest.bin %>% rename(group = pango_lineage) %>% filter(group != "others")  %>% group_by(date.bin.num) %>% mutate(freq = count / sum(count))
  
data.freq <- merge(data.freq,data_Id.df,by.x="date.bin.num",by.y="date_Id")
  
  
draw.df.theta <- fit.stan$draws("theta", format = "df") %>% as.data.frame() %>% select(! contains('.'))
#change from wide type to long type
draw.df.theta.long <- draw.df.theta %>% gather(key = class, value = value)
  
  
draw.df.theta.long <- draw.df.theta.long %>% mutate(date_Id = str_match(class,'theta\\[([0-9]+),[0-9]+\\]')[,2] %>% as.numeric(),
                                                      group_Id = str_match(class,'theta\\[[0-9]+,([0-9]+)\\]')[,2] %>% as.numeric())
  
  
draw.df.theta.long <- draw.df.theta.long %>% inner_join(data_Id.df,by="date_Id")
  
  
#add value
draw.df.theta.long.sum <- draw.df.theta.long %>% group_by(group_Id, date) %>% summarize(mean = mean(value),ymin = quantile(value,0.025),ymax = quantile(value,0.975))
  
draw.df.theta.long.sum <- draw.df.theta.long.sum %>% inner_join(group.df,by="group_Id")
draw.df.theta.long.sum <- draw.df.theta.long.sum %>% inner_join(data.freq %>% select(group,count,freq,date),by=c("date","group"))

#select mean top 5
variant.top.v.wo_ref <- stat.info %>% top_n(5,mean) %>% arrange(desc(mean)) %>% pull(Pango.lineage) %>% as.character()
  
draw.df.theta.long.sum.filtered <- draw.df.theta.long.sum %>% filter(group %in% variant.top.v.wo_ref) %>% unique()
draw.df.theta.long.sum.filtered <- draw.df.theta.long.sum.filtered %>% mutate(group = factor(group,levels=variant.top.v.wo_ref))
  
g <- ggplot(draw.df.theta.long.sum.filtered,aes(x=date, y = mean, fill=group, color = group))
g <- g + geom_point(aes(y=freq,size=count),alpha=0.4)
g <- g + geom_ribbon(aes(ymin=ymin,ymax=ymax), color=NA,alpha=0.4)
g <- g + geom_line(size=0.3)
g <- g + scale_x_date(date_labels = "%m-%d", date_breaks = "2 weeks", date_minor_breaks = "1 week")
g <- g + theme_set(theme_classic(base_size = 12, base_family = "Helvetica"))
g <- g + theme(panel.grid.major = element_blank(),
               panel.grid.minor = element_blank(),
               panel.background = element_blank(),
               strip.text = element_text(size=8)
)
g <- g + scale_color_brewer(palette = "Dark2")
g <- g + scale_fill_brewer(palette = "Dark2")
g <- g + scale_size_continuous(range = c(0.5, 5))
g <- g + ggtitle(region.interest)
g
  
#plot theta
pdf(pdf.theta.name,width=6,height=6.5)
plot(g)
dev.off()
  
