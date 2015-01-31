require(stringr)
require(rjson)
source('utils.r')

data.path <- '../data/'
sys.files <- Sys.glob(data.path %.% "*.sys")

data <- list()

for (file in sys.files) {
    print(file)
    lines <- readLines(file)
    props <- capply(lines, function(l) {
        if (str_detect(l, '#')) 
            return()
        
        p <- str_match(l, '(.+?)\\s+(.+)')
        if (any(is.na(p)))
            return()
        else {
            return(p[2:3])
        }
    }, USE.NAMES=FALSE)

    props.rvs <- props[2, props[1,] == 'RV[]']
    props <- props[, props[1,] != 'RV[]']

    props.list <- as.list(props[2,])
    names(props.list) <- props[1,]
    props.list$rvFiles <- props.rvs

    props.list$rv <- lapply(props.rvs, function(f) {
        return(read.table(data.path %.% f))
    })

    props.list$rvProps <- lapply(props.rvs, function(f) {
        lines <- readLines(data.path %.% f)
        lines <- lines[str_detect(lines, '#')]
        return(sapply(lines, function(l) {
            p <- str_trim(str_match(l, '#(.+?)=(.+)'))
            v <- p[3]
            names(v) <- p[2]
            return(v)
        }, USE.NAMES=FALSE))
    })
    
    data <- c(data, props.list)
}

cat(toJSON(data), file=data.path %.% 'data.json')
