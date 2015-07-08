library(plyr)
library(dplyr)
library(readr)

rms <- function(a) sqrt(sum(a^2)/length(a))

# Read all the RV observations
data <- ldply(Sys.glob("../data/*.vels"), function(f) {
  cbind(read.table(f, col.names=c('time', 'value', 'err')), fn=basename(f),
        star=str_match(basename(f), '(.+?)_')[1, 2])
})

# Read all the star data
star_data_fields <- c("name", "mass", "hd", "hip", "teff", "ra", "dec")
extract <- function(list, names) {
  return(setNames(list[names], names))
}

# Combined view over all the .sys and .vels files
combined_star_data <- ldply(Sys.glob("../data/*.sys"), function(f) {
  ret <- str_match(readLines(f), "(.+)\\t(.+)")[, 2:3]
  ret[,1] <- str_to_lower(str_trim(ret[,1]))
  ret[,2] <- str_trim(ret[,2])
  ret <- ret[!is.na(ret[,1]), ]
  l <- extract(setNames(ret[,2], ret[,1]), star_data_fields)

  basic_data <- do.call(data_frame, as.list(l))
  rvs <- ret[ret[,1] == "rv[]", 2]
  
  more_data <<- Reduce(rbind, lapply(str_c('../data/', rvs), function(f) cbind(read.table(f), f))) %>%
    group_by(f) %>%
    mutate(V2=V2-median(V2)) %>%
    ungroup() %>%
    summarise(min_time=min(V1), max_time=max(V1), time_span=max_time-min_time, rms=round(rms(V2), 2),
              nsets=length(rvs))
  
  data <- cbind(basic_data, more_data,
           telescopes=str_c(str_to_upper(str_match(rvs, "([[:alnum:]]+?)\\.vels")[,2]), collapse=", "))
}, .parallel=TRUE, .progress=TRUE)

combined_star_data <- combined_star_data %>%
  mutate(teff=as.numeric(teff), mass=as.numeric(mass), ra=as.numeric(ra),
         dec=as.numeric(dec))

saveRDS(file='combined_star_data.rds', combined_star_data)
write.csv(file='combined_star_data.csv', combined_star_data)
