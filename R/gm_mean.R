# function to calculate geometric mean of percentiles while removing NAs

gm_mean <-  function(x){

  exp(mean(log(x), na.rm = TRUE))
  
}
