######################################################
# Title: LandfireTrainingData
# Description: Generating training data from LANDFIRE
# Author: Melissa M. Rohde
# Last Modified: Nov 3, 2022
#######################################################


require (ggplot2)
library (data.table)
library(dplyr)
library(plyr)
library(gridExtra)
library(grid)
library(TTR)
library(zoo)
library(RColorBrewer)
library(reshape)
library(lubridate)
library(lme4)
library(strucchange)
library(tree)
library(httr) #API
library(jsonlite) #API
library(tidyverse) #API
library(rlist)
library(googledrive)
library(tidyquant)
library(RCurl)
library(ggstance)
library(forcats)
library(mblm)
library(cowplot)
options(stringsAsFactors = FALSE)

###################################################
## ~~~~~~~~~~~~~~~LOAD DATASETS~~~~~~~~~~~~~~~~~~##
###################################################


####### VegCamp ######
vegcamp <- read.csv('~/vegcamp_GDE_review_20161107.csv',header=TRUE, sep=",")
vegcamp[,c(1,4,5,7:26)]<-NULL
colnames(vegcamp)<- c("TKW_gde","TKW_cert","DomSp")
vegcamp<-vegcamp[!duplicated(vegcamp$DomSp),]  #Remove duplicated species

####### Other? ######
Other <- read.csv('~/tbl_DomSp_Unique_NW_SW.csv',header=TRUE, sep=",")
Other[,3]<-NULL
colnames(Other)<- c("DomSp","SciLit_gde")
Combo<- left_join(Other,vegcamp,by="DomSp")

#Load google sheet with AZ, OR, NV, and CA phreatophytes identified in the Landfire list
Landfire_TrainingData <- read.csv('~/Landfire_TrainingData.csv',header=TRUE,sep=",")
colnames(Landfire_TrainingData)<- c("DomSp","CA","OR","NV","AZ")

#Join to CA_vegcamp info
Landfire<- left_join(Combo, Landfire_TrainingData, by="DomSp")


#Assign GDE classification according to ranking
Landfire$CAconsensus <- "No"
Landfire$CAconsensus[which(Landfire$CA==Landfire$TKW_gde)]<-"Yes"
Landfire$CAconsensus[which(is.na(Landfire$TKW_gde))]<- "missing"

Landfire$CA_CLASS <- NA #Set default to non-GDE
Landfire$CA_cert <- NA #Set default to no certainty

for (i in 1:length(Landfire$DomSp)){
  if(Landfire$SciLit_gde[i] == 1){  
    Landfire$CA_CLASS[i]<-1  #designate gdes for DomSp backed up with literature reviewed citations.
    Landfire$CA_cert[i]<- 1 #designate high certainty for lit reviewed DomSp.
  }
  else if (Landfire$SciLit_gde[i]==0){
    if (Landfire$CAconsensus[i]=="missing"){ # if TKW data is NA then use rooting depth sources (CA)
      Landfire$CA_CLASS[i]<- Landfire$CA[i]
      Landfire$CA_cert[i]<- 1
    }
    else {
      if (Landfire$CAconsensus[i]=="Yes"){ #if there is consensus between TKW and rooting depth sources then use GDE designation with high certainty
        Landfire$CA_CLASS[i]<- Landfire$CA[i]
        Landfire$CA_cert[i]<- 1
      }
      else {
        if ((Landfire$CAconsensus[i]=="No")){ #if there is no consensus between TKW and rooting depth sources then use GDE designation according to rooting depth with medium certainty
          Landfire$CA_CLASS[i]<- Landfire$CA[i]
          Landfire$CA_cert[i]<- 2
        }}}}}

Landfire$CA_cert[which(Landfire$CAconsensus=="No")]<-2 #designate medium certainty if there is no consensus in CA

#Reclassify 0=NA, 1=gde, and 2=non-gde
Landfire$NV_class<-NA
Landfire$NV_class[which(Landfire$NV==0)]<-2
Landfire$NV_class[which(Landfire$NV==1)]<-1
Landfire$NV_class[which(is.na(Landfire$NV))]<-0

Landfire$OR_class<-NA
Landfire$OR_class[which(Landfire$OR==0)]<-2
Landfire$OR_class[which(Landfire$OR==1)]<-1
Landfire$OR_class[which(is.na(Landfire$OR))]<-0

Landfire$AZ_class<-NA
Landfire$AZ_class[which(Landfire$AZ==0)]<-2
Landfire$AZ_class[which(Landfire$AZ==1)]<-1
Landfire$AZ_class[which(is.na(Landfire$AZ))]<-0

Landfire$CA_class<-NA
Landfire$CA_class[which(Landfire$CA_CLASS==0)]<-2
Landfire$CA_class[which(Landfire$CA_CLASS==1)]<-1
Landfire$CA_class[which(is.na(Landfire$CA_CLASS))]<-0

Landfire_List <- Landfire[,c(1,12:15)]

Landfire_List$gde_class<-NA
Landfire_List$gde_cert<-NA

for (i in 1:length(Landfire_List$DomSp)){
  if (sum(Landfire_List[i,2:5]==2)>=1 ){ # When the number of states that indicate a non-gde is gte 1....
    Landfire_List$gde_class[i]<-2 #When any state lists a Dom Sp as non-gde it is a non-gde
    Landfire_List$gde_cert[i]<-2  #Medium certainty as default when any state designates Dom Sp as non-gde
  }
  if (sum(Landfire_List[i,2:5]==1)>=1 ){ # When the number of states that indicate a gde is gte 1....
    Landfire_List$gde_class[i]<-1 #When any state lists a Dom Sp as gde it is a gde
    Landfire_List$gde_cert[i]<-2  #Medium certainty as default when any state designates Dom Sp as gde
  }
  if (sum(Landfire_List[i,2:5]==1)==4){# When all four states indicate a gde.
    Landfire_List$gde_cert[i]<-1  #High certainty when all states designate Dom Sp as gde
  }
  if (sum(Landfire_List[i,2:5]==1)==1){ #When only one state indicates a gde
    Landfire_List$gde_cert[i]<-3 #Low certainty when only one state designates Dom sp as gde
  }
  if (sum(Landfire_List[i,2:5]==2)==4){# When all four states indicate a non-gde.
    Landfire_List$gde_class[i]<-2 #When all states list a Dom Sp as non-gde it is a non-gde
    Landfire_List$gde_cert[i]<-1  #High certainty when all states designate Dom Sp as non-gde
  }
  if (sum(Landfire_List[i,2:5]==0)==4){   # When all four states are NA
    Landfire_List$gde_class[i]<-0
    Landfire_List$gde_cert[i]<-0
  }
  
}

Landfire_List$gde_type<- "Vegetation"
Landfire_List$gde_source<- "Landfire"
Landfire_List$gde_descr<-Landfire_List$DomSp



write.csv(Landfire_List,file="~/Dropbox/GDEmap/Landfire_List.csv",row.names=TRUE)

Landfire_List <- read.csv("~/Dropbox/GDEmap/Landfire_List.csv",header=TRUE, sep=",")
