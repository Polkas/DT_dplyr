
pacman::p_load("dplyr", "tidyr", "readr", "readxl","data.table","microbenchmark","R.utils",'purrr')

spec = read_csv("./data/daily_SPEC_2014.csv.bz2",col_types = paste0(c("iii",rep("?",26)),collapse = ""))

specDT = fread("./data/daily_SPEC_2014.csv.bz2")

#specDT = data.table(spec)

##################What is average Arithmetic.Mean for “Bromine PM2.5 LC” in the state of Wisconsin in this dataset?
iters=10

spec %>%
  filter(`Parameter Name` == "Bromine PM2.5 LC", `State Name` == "Wisconsin") %>%
  select(`Arithmetic Mean`) %>% map_dbl(.,mean,na.rm=T)

specDT[`Parameter Name` == "Bromine PM2.5 LC" & `State Name` == "Wisconsin",mean(`Arithmetic Mean`,na.rm=T),]

microbenchmark(dplyr=spec %>%
                 filter(`Parameter Name` == "Bromine PM2.5 LC", `State Name` == "Wisconsin") %>%
                 select(`Arithmetic Mean`) %>%
                 unlist() %>%
                 mean(na.rm=T),
               DT = specDT[`Parameter Name` == "Bromine PM2.5 LC" & `State Name` == "Wisconsin",mean(`Arithmetic Mean`,na.rm=T),],times=iters)

###data.table index and key

###key

setkey(specDT,`Parameter Name`,`State Name`) #Data is sorted

microbenchmark(dplyr=spec %>%
                 filter(`Parameter Name` == "Bromine PM2.5 LC", `State Name` == "Wisconsin") %>%
                 select(`Arithmetic Mean`) %>%
                 unlist() %>%
                 mean(na.rm=T),
               DT = specDT[`Parameter Name` == "Bromine PM2.5 LC" & `State Name` == "Wisconsin",mean(`Arithmetic Mean`,na.rm=T),],
               DT_key = specDT[.(c("Bromine PM2.5 LC"),"Wisconsin"),mean(`Arithmetic Mean`,na.rm=T),on=c("Parameter Name","State Name")] #on fonly for readability
               ,times=iters)

###index

specDT = data.table(spec)

setindex(specDT,`Parameter Name`,`State Name`) #Data is not sorted but assess and save index

microbenchmark(dplyr=spec %>%
                 filter(`Parameter Name` == "Bromine PM2.5 LC", `State Name` == "Wisconsin") %>%
                 select(`Arithmetic Mean`) %>%
                 unlist() %>%
                 mean(na.rm=T),
               DT = specDT[`Parameter Name` == "Bromine PM2.5 LC" & `State Name` == "Wisconsin",mean(`Arithmetic Mean`,na.rm=T),],
               DT_on=specDT[.(c("Bromine PM2.5 LC"),"Wisconsin"),mean(`Arithmetic Mean`,na.rm=T),on=c("Parameter Name","State Name")],times=iters)

###index on the fly

specDT = data.table(spec)

microbenchmark(dplyr=spec %>%
                 filter(`Parameter Name` == "Bromine PM2.5 LC", `State Name` == "Wisconsin") %>%
                 select(`Arithmetic Mean`) %>%
                 unlist() %>%
                 mean(na.rm=T),
               DT = specDT[`Parameter Name` == "Bromine PM2.5 LC" & `State Name` == "Wisconsin",mean(`Arithmetic Mean`,na.rm=T),],
               DT_on=specDT[.(c("Bromine PM2.5 LC"),"Wisconsin"),mean(`Arithmetic Mean`,na.rm=T),on=c("Parameter Name","State Name")],times=iters)

##################Calculate the average of each chemical constituent across all states, monitoring sites and all time points. 
##################Which constituent Parameter.Name has the highest average level?

specDT = data.table(spec)

spec %>%
  group_by(`Parameter Name`,`State Name`,`Local Site Name`,`Date Local`) %>%
  summarise(avg = mean(`Arithmetic Mean`,na.rm=T)) %>% ungroup() %>% slice(which.max(avg))

specDT[,.(avg = mean(`Arithmetic Mean`,na.rm=T)),
       by=list(`Parameter Name`,`State Name`,`Local Site Name`,`Date Local`)][which.max(avg)]

microbenchmark(dplyr = spec %>%
                 group_by(`Parameter Name`,`State Name`,`Local Site Name`,`Date Local`) %>%
                 summarise(avg = mean(`Arithmetic Mean`,na.rm=T)) %>% ungroup() %>% slice(which.max(avg))
                 ,
               DT=specDT[,.(avg = mean(`Arithmetic Mean`,na.rm=T)),
                         by=list(`Parameter Name`,`State Name`,`Local Site Name`,`Date Local`)][which.max(avg)],times=iters)

####################Which monitoring site has the highest average level of “Sulfate PM2.5 LC” across all time? 
####################Indicate the state code, county code, and site number.

specDT["Sulfate PM2.5 LC",
       .(mean = mean(`Arithmetic Mean`,na.rm=T)),
       by=c("Local Site Name","State Code","County Code","Site Num"),
       on = c("Parameter Name")][order(desc(mean))] %>% .[!is.na(`Local Site Name`),]

spec %>% filter(`Parameter Name`=="Sulfate PM2.5 LC") %>%
  group_by(`Local Site Name`,`State Code`,`County Code`,`Site Num`) %>% 
  summarise(mean = mean(`Arithmetic Mean`,na.rm=T)) %>% 
  arrange(desc(mean)) %>% filter(!is.na(`Local Site Name`))


microbenchmark(dplyr = spec %>% filter(`Parameter Name`=="Sulfate PM2.5 LC") %>%
                 group_by(`Local Site Name`,`State Code`,`County Code`,`Site Num`) %>% 
                 summarise(mean = mean(`Arithmetic Mean`,na.rm=T)) %>% 
                 arrange(desc(mean)) %>% filter(!is.na(`Local Site Name`)),
               DT = specDT["Sulfate PM2.5 LC",
                           .(mean = mean(`Arithmetic Mean`,na.rm=T)),
                           by=c("Local Site Name","State Code","County Code","Site Num"),
                           on = c("Parameter Name")][order(desc(mean))] %>% .[!is.na(`Local Site Name`),],times=iters)

###################What is the absolute difference in the average levels of “EC PM2.5 LC TOR” between the states California and Arizona, across all time and all monitoring sites?

specDT[.("EC PM2.5 LC TOR",c("California","Arizona")),
       mean(`Arithmetic Mean`,na.rm=T),
       by = "State Name",
       on = c("Parameter Name","State Name")]

spec %>% filter((`State Name` %in% c("California","Arizona")) & (`Parameter Name`== "EC PM2.5 LC TOR")) %>% group_by(`State Name`) %>% summarise(mean=mean(`Arithmetic Mean`,na.rm=T))


microbenchmark(dplyr=spec %>% filter((`State Name` %in% c("California","Arizona")) & (`Parameter Name`== "EC PM2.5 LC TOR")) %>% group_by(`State Name`) %>% summarise(mean=mean(`Arithmetic Mean`,na.rm=T))
,
DT=specDT[.("EC PM2.5 LC TOR",c("California","Arizona")),
          mean(`Arithmetic Mean`,na.rm=T),
          by = "State Name",
          on = c("Parameter Name","State Name")],times=iters )

##################What is the median level of “OC PM2.5 LC TOR” in the western United States, across all time? 
##################Define western as any monitoring location that has a Longitude LESS THAN -100.

specDT[(`Parameter Name` == "OC PM2.5 LC TOR") & (Longitude < -100),
       median(`Arithmetic Mean`,na.rm=T)] #,by = "State Name"]

spec %>% filter((`Parameter Name` == "OC PM2.5 LC TOR") & (Longitude < -100)) %>% summarise(median=median(`Arithmetic Mean`,na.rm=T))

##################How many monitoring sites are labelled as both RESIDENTIAL for "Land Use" and SUBURBAN for "Location Setting"?

aqs = read_excel("./data/aqs_sites.xlsx")

aqsDT = data.table(aqs)

aqsDT[.("RESIDENTIAL","SUBURBAN"),.N,on=c("Land Use","Location Setting")]


##################merging

spec_aqs = spec %>% left_join(aqs,by=intersect(colnames(spec ),colnames(aqs)))

spec_aqsDT = merge(specDT,aqsDT,by=intersect(colnames(spec ),colnames(aqs)),all.x = T)

##################What is the median level of “EC PM2.5 LC TOR” amongst monitoring sites that are labelled as both “RESIDENTIAL” and “SUBURBAN” in the eastern U.S., 
##################where eastern is defined as Longitude greater than or equal to -100?

spec_aqs %>% filter((`Parameter Name` == "EC PM2.5 LC TOR") & (Longitude >= -100) & (`Land Use` == "RESIDENTIAL") & (`Location Setting` == "SUBURBAN")) %>% summarise(median=median(`Arithmetic Mean`,na.rm=T))

spec_aqsDT[(`Parameter Name` == "EC PM2.5 LC TOR") & (Longitude >= -100) & (`Land Use` == "RESIDENTIAL") & (`Location Setting` == "SUBURBAN"),median(`Arithmetic Mean`,na.rm=T)]

##################Amongst monitoring sites that are labeled as COMMERCIAL for "Land Use", 
##################which month of the year has the highest average levels of "Sulfate PM2.5 LC"?

spec_aqs %>% filter(`Parameter Name` == "Sulfate PM2.5 LC" & (`Land Use` == "COMMERCIAL")) %>%
group_by( month(`Date Local`)) %>%
      summarise(mean = mean(`Arithmetic Mean`,na.rm=T)) %>% arrange(desc(mean))

spec_aqsDT[(`Parameter Name` == "Sulfate PM2.5 LC") & (`Land Use` == "COMMERCIAL"),
       .(mean = mean(`Arithmetic Mean`,na.rm=T)),by = month(`Date Local`)][order(desc(mean))]

##################Take a look at the data for the monitoring site identified by State Code 6, County Code 65, and Site Number 8001 (this monitor is in California). 
##################At this monitor, for how many days is the sum of "Sulfate PM2.5 LC" and "Total Nitrate PM2.5 LC" greater than 10?

specDT[`State Code` == 6 &
         `County Code` ==  65 &
         `Site Num` == 8001 &
         (`Parameter Name` == "Sulfate PM2.5 LC" | `Parameter Name` == "Total Nitrate PM2.5 LC"),
       .(mean = mean(`Arithmetic Mean`)), # mean of a few measures at the same day of certain parameter 
       by=c("Parameter Name","Date Local")][,.(sum = sum(mean)),by = "Date Local"][sum>10,.N,]

spec %>% filter((`State Code` == 6) &
         (`County Code` ==  65) &
         (`Site Num` == 8001) & (`Parameter Name` == "Sulfate PM2.5 LC" | `Parameter Name` == "Total Nitrate PM2.5 LC")) %>%
  group_by(`Parameter Name`,`Date Local`) %>% summarise(mean=mean(`Arithmetic Mean`)) %>% group_by(`Date Local`) %>% summarise(sum=sum(mean)) %>% filter(sum>10) %>% summarise(n=n())

###################Which monitoring site in the dataset has the highest correlation between "Sulfate PM2.5 LC" and "Total Nitrate PM2.5 LC" across all dates? 
###################Identify the monitoring site by it's State, County, and Site Number code.


spec %>% filter((`Parameter Name` == "Sulfate PM2.5 LC") | (`Parameter Name` == "Total Nitrate PM2.5 LC")) %>%
  group_by_at(vars(c("Parameter Name","Date Local","State Code", "County Code","Site Num"))) %>%
  summarise(mean = mean(`Arithmetic Mean`)) %>% 
  spread(`Parameter Name`,mean) %>% 
  group_by_at(vars(c("State Code", "County Code","Site Num"))) %>% 
  summarise(cor=cor(`Sulfate PM2.5 LC`,`Total Nitrate PM2.5 LC`,use="pairwise.complete.obs")) %>% arrange(desc(cor))


dat = specDT[(`Parameter Name` == "Sulfate PM2.5 LC" | `Parameter Name` == "Total Nitrate PM2.5 LC"),
       .(mean = mean(`Arithmetic Mean`)),
       by=c("Parameter Name","Date Local","State Code", "County Code","Site Num")]

dat_2 = data.table::dcast(dat, `Date Local` + `State Code` +`County Code` +`Site Num`   ~ `Parameter Name`, value.var = "mean") #Revert - data.table::melt(dat_2, id=1:4,measure=5:6)

data.table(dat_2)[,cor(`Sulfate PM2.5 LC`,`Total Nitrate PM2.5 LC`,use="pairwise.complete.obs"),by = c("State Code", "County Code","Site Num")][order(desc(V1))]


##############
##############

