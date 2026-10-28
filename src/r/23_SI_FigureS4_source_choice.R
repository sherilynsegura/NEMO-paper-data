# Script: 23_SI_FigureS4_source_choice.R
# Reports: Figure S4A–B. Child choice proportions by age and configuration.

# Set up paths and shared helpers -------------------------------------
script_id <- "23_SI_FigureS4_source_choice"
repo_root <- Sys.getenv("NEMO_REPO_ROOT",getwd())
source(file.path(repo_root,"src","r","_setup.R"),local=TRUE)
library(dplyr); library(tidyr); library(ggplot2)

# Load data and prepare the analysis sample ---------------------------
d <- read.csv(input_file) %>% filter(wave %in% 7:10,choseSource==1,!is.na(age),age>=6,age<=18,is.na(z_resid)|abs(z_resid)<3,socialSource %in% 1:3) %>%
 mutate(configuration=ifelse(wave %in% 7:8,"One dyad","Two dyads"),source=factor(socialSource,levels=1:3,labels=c("Vertical","Oblique","Horizontal")))

# Summarise choices by age and configuration --------------------------
proportions <- d %>% count(configuration,age,source) %>% group_by(configuration,age) %>% mutate(proportion=n/sum(n)) %>% ungroup()
counts <- d %>% group_by(configuration,age) %>% summarise(participants=n_distinct(ppt),.groups="drop")

# Draw configuration-specific choice panels ---------------------------
plot_choice <- ggplot(proportions,aes(factor(age),proportion,fill=source))+geom_col()+facet_wrap(~configuration)+
 geom_text(data=counts,aes(factor(age),1.04,label=participants),inherit.aes=FALSE)+
 scale_fill_manual(values=c(Vertical="#F8766D",Oblique="#00BA38",Horizontal="#619CFF"))+
 coord_cartesian(ylim=c(0,1.08))+labs(x="Child age (years)",y="Proportion of choices",fill="Pathway")+theme_minimal()
write.csv(proportions,file.path(table_dir,"choice_proportions.csv"),row.names=FALSE)

# Save figure and counts ----------------------------------------------
save_plot(plot_choice,"plot_choice")
capture.output(sessionInfo(),file=file.path(output_dir,"sessionInfo.txt"))
