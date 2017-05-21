rm(list=ls(all=TRUE))

library(plyr)
library(tidyr)
library(ggplot2)
library(sqldf)
library(readr)
library(xtable)
library(gtools)

source("multiplot.R")
library(dplyr)


###########################
# READ DATA ###############
###########################

sizes <- rep(c(17, 53, 34, 39, 48, 56, 65, 48), each=3)

solutions <- read_csv("~/combinatorial-optimization-ulb/solutions/solutions.csv", 
                      col_types = cols(random_seed = col_skip()))

solutions <- subset(solutions, !instance_name %in% c("8.atsp", "9.atsp")) 

# Clean name
solutions$instance_name <- gsub(".atsp", "", solutions$instance_name)

# Group data by name
sgroup <- solutions %>%
  dplyr::group_by(instance_name, constraints_type, hot_start, solution_value) %>%
  dplyr::summarise(time=median(exec_time)) %>%
  arrange(as.numeric(instance_name))

# Add sizes
sgroup$size <- sizes

ggplot(sgroup, aes(x=reorder(instance_name, as.numeric(instance_name)), y=time, fill=constraints_type)) + geom_col(alpha=0.5, position="dodge") + 
  labs(title ="Execution time, divided by constraint type", x = "Instance number", y = "Execution time [sec]") +
  theme_minimal() + scale_fill_brewer(palette="Accent")

ggplot(sgroup, aes(x=constraints_type, y=time, fill=constraints_type, color=constraints_type)) + geom_boxplot(alpha=0.5, position="dodge") + 
  labs(title ="Execution time, divided by constraint type", x = "Instance number", y = "Execution time [sec]") +
  theme_minimal() + scale_fill_brewer(palette="Accent") + scale_color_brewer(palette="Accent")

ggplot(sgroup %>% dplyr::group_by(size, constraints_type) %>% dplyr::summarise(time=mean(time)), aes(x=size, y=time, fill=constraints_type, color=constraints_type)) + geom_area(alpha=0.3, size=1) + 
  labs(title ="Execution time as function of instance size", x = "Instance size", y = "Execution time [sec]") +
  theme_minimal() + scale_fill_brewer(palette="Accent") + scale_color_brewer(palette="Accent")

# Tables 
res <- sgroup %>% dplyr::group_by(constraints_type) %>% dplyr::summarize(min=min(time), mean=mean(time), median=median(time), max=max(time), sd=sd(time))
xtable(res,display = c("s", "f", "f", "f", "f", "f", "f"))