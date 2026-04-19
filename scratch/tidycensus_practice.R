source("setup.R")
library(tidycensus)

#api key saved to env. when using census_api_key("api from Census Bureau",install=TRUE)
api_key <- Sys.getenv("CENSUS_API_KEY")
census_api_key(api_key)

#just to see if I can pull anything
age20 <- get_decennial(geography = "state",
                       variables = "P13_001N",
                       year=2020,
                       sumfile = "dhc")
head(age20)

age20 %>% ggplot((aes(x=value,y=reorder(NAME,value))))+
  geom_point()
