JD.start <- 2440000

tbl <- function(t) {
    return(apply(data[[i]], 1, function(row) {
                return(str_join(sprintf("%f", row), collapse='\t'))
            }))
}

intersections <- function(m) {
    r <- apply(combn(1:ncol(m), 2), 2, function(pair) {
        r1 <- m[, pair[1]]
        r2 <- m[, pair[2]]

        if (r2[1] < r1[2] && r1[1] < r2[2])
            return(pair)
        else
            return(c(NA, NA))
    })

    return(r[,!is.na(r[1,]), drop=F])
}

header <- function(h, prop) {
    return(h[str_detect(h, str_join("# ", prop))])
}

# Removes duplicate .vels files
require(stringr)
sys.files <- Sys.glob("*.sys")

for (sys.file in sys.files) {
    cat("Checking ", sys.file, "\n")
    lines <- readLines(sys.file)
    rv.lines <- lines[str_detect(lines, "RV\\[\\]")]
    sys.props <- lines[!str_detect(lines, "RV\\[\\]")]
    
    rv.files <- str_match(rv.lines, "\t(.+)")[,2]
    if (length(rv.files) == 1)
        next
    
    counter <- 1

    data <- lapply(rv.files, function(f) {
        return(read.table(f))
    })
    headers <- lapply(rv.files, function(f) {
        l <- readLines(f)
        return(l[str_detect(l, "#")])
    })
    time.ranges <- sapply(data, function(d) range(d[,1]))

    if (any(time.ranges < JD.start)) {
        idx <- which(time.ranges[1,] < JD.start)

        data[idx] <- lapply(data[idx], function(d) {
            d[,1] <- d[,1] + JD.start
            return(d)
        })
        time.ranges <- sapply(rv.files, function(f) range(read.table(f)[,1]))

        for (i in idx) {
            print(i)
            print(rv.files[i])
            conn <- file(rv.files[i], 'w')
            writeLines(headers[[i]], conn)

            writeLines(tbl(data[[i]]), conn)
            
            close(conn)
        }
        
        stop("Correct JDs on ", rv.files[idx])
    }
    r <- intersections(time.ranges)
    print(time.ranges)
    changed <- TRUE
    
    if (!is.null(r)) {
        cat(rep('=', 60), '\n', sep="")
        apply(r, 2, function(p) {
            for (i in p) {
                cat('\n')
                cat(i, ". ", rv.files[i], '\n')
                cat('JD range: ', time.ranges[,i], '\n', sep=' ')
                for (prop in c('telescope', 'instrument', 'reference'))
                    cat(prop, ':',  header(headers[[i]], prop), '\n')
            }

            cat("\nWhat do? [0 = keep both, 1 = keep first, 2 = keep second] ")
            resp <- readLines(n=1)
            if (resp == 1) {
                #delete.file(rv.files[p[2]])
                rv.files <- rv.files[-p[2]]
                rv.lines <- rv.lines[-p[2]]
            } else if (resp == 2) {
                #delete.file(rv.files[p[1]])
                rv.files <- rv.files[-p[1]]
                rv.lines <- rv.lines[-p[1]]
            }
        })
        print(rv.files)
    }

   
}
