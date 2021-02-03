####load packages####
library(dplyr)
library(magrittr)
library(ggplot2)
library(ggthemes)
library(tidyquant)
library(data.table)


####參數####
enddate<-as.Date("2021-02-03")
filename<-paste0("3rd_",enddate,".csv")

####歷史日期####
# historyDate<-data.frame(date=(seq(enddate-365,enddate,1))) %>%
#   arrange(desc(date))
# write.csv(historyDate,"./history.csv",row.names = F)

####合併歷史資料(外資/投信) (一天跑一次就好)####
setwd("./三大法人買賣超")
filelist<-list.files(pattern = ".csv")
stock3rd<-data.frame()
for (i in 1:length(filelist)) {
  stock3rd<-bind_rows(stock3rd,read.csv(filelist[i],encoding = "utf-8"))
}
setwd("..")
write.csv(stock3rd, file = paste0("3rd_",enddate,".csv"),row.names = F)


####select####
stock3rdanaTB<-fread(filename)
stock3rdselect<-stock3rdanaTB %>%
  mutate(date=as.Date(date), foreign=as.numeric(gsub(",","",foreign), credit=as.numeric(gsub(",","",credit)))) %>%
  group_by(code) %>%
  arrange(code,date) %>%
  mutate(lagdate=lag(date,n=2)) %>%
  filter(!is.na(foreign) & !is.na(credit)) %>%
  filter(date<=enddate & date>=lagdate) %>%
  mutate("外資連續買超3日"=ifelse((foreign>80*1000 &
                              lag(foreign,n=1)>0 &
                              lag(foreign,n=2)>0) & (credit>=0),1,0)) %>%
  slice_tail(n=1) %>%
  ungroup() %>%
  filter(外資連續買超3日==1) %>%
  mutate(code=paste0(code,".TW"))
write.csv(stock3rdselect,paste0("./選股/select_",enddate,".csv"),row.names = F)  

####filter data####
df<-read.csv(paste0("./選股/select_",enddate,".csv"))
selectlist<-df$code
selectstock<-tq_get(selectlist,from=enddate-100,to=enddate+1) %>%
  rename("code"=symbol) %>%
  filter(!is.na(close)) %>%
  arrange(code,date) %>%
  group_by(code) %>%
  add_count(code) %>%
  ungroup() %>%
  filter(n>=60) %>%
  group_by(code) %>%
  tq_mutate(select = close, mutate_fun = SMA, n=10) %>%
  rename(ma10=SMA) %>%
  tq_mutate(select = close, mutate_fun = SMA, n=20) %>%
  rename(ma20=SMA) %>%
  tq_mutate(select = close, mutate_fun = SMA, n=60) %>%
  rename(ma60=SMA) %>%
  slice_tail(n=1) %>%
  ungroup() %>%
  filter((close>ma20 & ma10>ma60 & ma10>ma20 & volume>2000000) | (low>ma10 & low>ma20 & low>ma60 & volume>4000000)) %>%
  mutate(stockclass=ifelse(low>ma10 & low>ma20 & low>ma60 & volume>4000000,"2rd","")) %>%
  mutate(stockclass=ifelse(close>ma20 & ma10>ma60 & ma10>ma20 & volume>2000000,"1st",stockclass)) %>%
  arrange(stockclass,close) %>%
  left_join(.,select(stock3rdselect,code,name),by="code") %>%
  select(code,name,date,open,high,low,close,volume,ma10,ma20,ma60,stockclass)
  
write.csv(selectstock,paste0("./選股/select_filter_",enddate,".csv"),row.names = F)  

####查個股####
stockname<-"2409"

stockdf<-fread(filename) %>%
  filter(code==stockname) %>%
  mutate(code=paste0(code,".TW"),date=as.Date(date))
  
stockdfjoin<-tq_get(paste0(stockname,".TW"),from=stockdf$date[1],to=(stockdf$date[nrow(stockdf)]+1)) %>%
  left_join(.,stockdf,by="date") %>%
  select(code,name,date,open,close,volume,foreign) %>%
  mutate(foreign=as.numeric(gsub(",","",foreign))) %>%
  arrange(desc(date))
