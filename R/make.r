# Rebuilds database 
systemic()
library(plyr)
library(dplyr)
library(readr)
library(ggplot2)
library(astroFns)
source("periodogram.r")
      
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

props <- function(lines) {
  ret <- str_match(lines, "(.+?)\\s+(.+)")[, 2:3]
  ret[,1] <- str_to_lower(str_trim(ret[,1]))
  ret[,2] <- str_trim(ret[,2])
  ret <- ret[!is.na(ret[,1]) & !str_detect(ret[,1], '#'), ]
  linked <- ret[ret[,1] == "rv[]", 2]
  ret <- ret[ret[,1] != 'rv[]', ]
  list(props = setNames(ret[,2], ret[,1]),
           linked = linked)
}

# Combined view over all the .sys and .vels files
combined_star_data <- ldply(Sys.glob("../data/*.sys"), function(f) {
  data <- props(readLines(f))
  
  l <- extract(data$props, star_data_fields)

  basic_data <- do.call(data_frame, as.list(l))
  
  more_data <- Reduce(rbind, lapply(str_c('../data/', data$linked), function(f) cbind(read.table(f), f))) %>%
    group_by(f) %>%
    mutate(V2=V2-median(V2)) %>%
    ungroup() %>%
    summarise(min_time=min(V1), max_time=max(V1), time_span=max_time-min_time, rms=round(rms(V2), 2),
              nsets=length(data$linked), ndata=n())
  
  data <- cbind(basic_data, more_data,
               telescopes=str_c(str_to_upper(str_match(data$linked, "([[:alnum:]]+?)\\.vels")[,2]), collapse=", "),
               fn=basename(f))
}, .parallel=TRUE, .progress=TRUE)

combined_star_data <- combined_star_data %>%
  mutate(teff=as.numeric(teff), mass=as.numeric
  (mass), ra=as.numeric(ra),
         dec=as.numeric(dec))

saveRDS(file='combined_star_data.rds', combined_star_data)
write.csv(file='combined_star_data.csv', combined_star_data)

all_data <- lapply(Sys.glob("../data/*.sys"), function(f) {
  props <- props(readLines(f))
  
  per <- attr(plotPeriodogram(f), 'peaks')
  if (!is.null(per))
    per <- per[1:min(5, nrow(per)), 1:3] 
  
  data <- c()
  sets <- lapply(str_c('../data/', props$linked), function(f) {
    data <<- rbind(data,
                 cbind(read.table(f, col.names=c('time', 'rv', 'error')),
                       telescope=str_match(f, "([[:alnum:]]+?)\\.vels")[,2]))
    list(
      fn = basename(f),
      header = paste(Filter(function(line) str_detect(line, '^\\#'), readLines(f)), collapse='\n')
    )      
  })

  data <- data[order(data$time), ]
  data <- cbind(data, date=sapply(data$time, function(x) as.character(jd2ymd(x))))
  row.names(data) <- NULL
  info <- combined_star_data[combined_star_data$fn == basename(f), ]

  return(list(props=info,
           name=props$props['name'],
           data=data,
           sets=sets,
           periodogram=per))
})

names(all_data) <- sapply(all_data, function(l) l$name)
saveRDS(all_data, '../app/all_data.rds')
