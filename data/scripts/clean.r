require(stringr)
source('commons.r')

JD.start <- 2440000


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
    
    if (!is.null(r)) {
        cat(rep('=', 60), '\n', sep="")
        remove <- c()
        apply(r, 2, function(p) {
            if (any(p %in% remove))
                return()

            for (i in p) {
                cat('\n')
                cat(i, ". ", rv.files[i], '\n')
                cat('JD range: ', time.ranges[,i], '\n', sep=' ')
                for (prop in c('telescope', 'instrument', 'reference'))
                    cat(prop, ':',  header(headers[[i]], prop), '\n')
            }

            datai <- data[[p[1]]]
            dataj <- data[[p[2]]]
            
            xlim <- range(c(datai[,1], dataj[,1]))
            ylim <- range(c(datai[,2], dataj[,2]))
            plot(datai[,1], datai[,2], col='red', pch=19, xlim=xlim, ylim=ylim)
            points(dataj[,1], dataj[,2], col='blue', pch=19)
            
            
            cat("\nWhat do? [0 = keep both, 1 = keep first, 2 = keep second] ")
            resp <- readLines(n=1)
            if (resp == 1) {
                changed <<- TRUE
                cat("Removing ", rv.files[p[2]], '\n')
                remove <<- c(remove, p[2])
            } else if (resp == 2) {
                changed <<- TRUE
                cat("Removing ", rv.files[p[1]], '\n')
                remove <<- c(remove, p[1])
            }
        })

        if (length(remove) > 0) {
            for (rv.file in rv.files[remove])
                file.remove(rv.file)

            rv.lines <- rv.lines[-remove]
            rv.files <- rv.files[-remove]

            for (i in 1:length(rv.files)) {
                new.name <- str_replace(rv.files[i], "_(\\d)_", sprintf("_%d_", i))
                file.rename(rv.files[i], new.name)
                rv.files[i] <- new.name
                rv.lines[i] <- str_join("RV[]\t", new.name)
            }

            conn <- file(sys.file, 'w')
            writeLines(c(sys.props, "\n"), conn)
            writeLines(rv.lines, conn)
            close(conn)
        }
        
    }

   
}
