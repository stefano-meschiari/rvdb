require(stringr)
source('common.r')
quartz()

JD.start <- 2440000


header <- function(h, prop) {
    l <- h[str_detect(h, str_join("# ", prop))]
    if (length(l) > 0)
        return(str_match(l, "= (.+)")[,2])
}

# Removes duplicate .vels files
sys.files <- Sys.glob("*.sys")

print('ok')
if (file.exists('done.txt')) {
    done <- readLines('done.txt')
} else {
    if (!exists('done'))
        done <- c()
}
done <- str_trim(done)

if (file.exists('actions.txt')) {
    actions <- readLines('actions.txt')
} else {
    actions <- c()
}

for (sys.file in sys.files) {
    cat("Checking ", sys.file, "\n")
    if (sys.file %in% done)
        next
    
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
    v.ranges <- sapply(data, function(d) range(d[,2]))
    v.ranges.m <- sapply(data, function(d) range(d[,2] - median(d[,2])))
    

    if (any(time.ranges < JD.start)) {
        idx <- which(time.ranges[1,] < JD.start)

        data[idx] <- lapply(data[idx], function(d) {
            d[,1] <- d[,1] + JD.start
            return(d)
        })
        time.ranges <- sapply(rv.files, function(f) range(read.table(f)[,1]))

        for (i in idx) {
            conn <- file(rv.files[i], 'w')
            writeLines(headers[[i]], conn)

            writeLines(tbl(data[[i]]), conn)
            
            close(conn)
        }
        
        actions <- c(actions, str_join('Corrected JDs on ', rv.files[idx]))
    }
    r <- intersections(time.ranges)
    has.km <- c()

    for (i in 1:length(headers))  {
        if (header(headers[[i]], 'value_units') == "KM/S")
            has.km <- c(has.km, i)
    }
    for (i in has.km) {
        medians <- sapply(data, function(d) median(d[,2]))
        v.ranges.m <- sapply(data, function(d) range(d[,2] - median(d[,2])))
        

        plot(data[[1]][,1], data[[1]][,2]-medians[i], xlim=range(time.ranges), ylim=range(v.ranges.m), col=1, pch=19,
             xlab='JD', ylab=str_join("RVs " , header(headers[[i]], 'value.unit')))
        for (j in 2:length(rv.files))
            points(data[[j]][,1], data[[j]][,2] - medians[j], pch=19, col=j)
        units <- sapply(headers, function(h) str_join(' ', header(h, 'value.unit')))
        
        legend(x='topleft', legend=str_join(rv.files, units), col=seq_along(rv.files), pch=19)

        cat(rv.files[i], ' is in ', header(headers[[i]], 'value.units'), '\n')           
        while (TRUE) {
            cat("Multiply RVs by 1000 [m], Open webpage [o] or is it Wrong and it should be m/s [w], or skip [RETURN]? [m/o/w/RETURN]? ")
            resp <- readLines(n=1)
            if (resp == 'm') {
                data[[i]][,2] <- (data[[i]][,2] - median(data[[i]][,2])) * 1000
                data[[i]][,3] <- data[[i]][,3] * 1000
                headers[[i]][str_detect(headers[[i]], 'KM/S')] <- '# value_units = M/S'
                f <- file(rv.files[i], 'w')
                writeLines(headers[[i]], f)
                writeLines(tbl(data[[i]]), f)
                close(f)
                actions <- c(actions, str_join(rv.files, '\t', resp))
                break
            } else if (resp == 'w') {
                headers[[i]][str_detect(headers[[i]], 'KM/S')] <- '# value_units = M/S'
                f <- file(rv.files[i], 'w')
                writeLines(headers[[i]], f)
                writeLines(tbl(data[[i]]), f)
                close(f)
                actions <- c(actions, str_join(rv.files, '\t', resp))
                break
            } else if (resp == 'o') {
                actions <- c(actions, str_join(rv.files, '\t', resp))                
                browseURL(header(headers[[i]], 'nexsci_url'))
                next
            } else
                break
            
        }
    }
    
    if (!is.null(r) && !ncol(r) == 0) {
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
            datai[,2] <- datai[,2] - median(datai[,2])
            dataj[,2] <- dataj[,2] - median(dataj[,2])
            
            
            xlim <- range(c(datai[,1], dataj[,1]))
            ylim <- range(c(datai[,2], dataj[,2]))
            plot(datai[,1], datai[,2],  pch=19, xlim=xlim, ylim=ylim, col=1, xlab='JD', ylab=header(headers[[p[1]]], 'value.units'))
            points(dataj[,1], dataj[,2],  pch=19, col=2)
            legend('topleft', legend=rv.files[p], pch=19, col=1:2)

            while (TRUE) {
            cat("\nWhat do? [RETURN = keep both, 1 = keep first, 2 = keep second, o = open webpage] ")
            resp <- readLines(n=1)
            if (resp == 1) {
                cat("Removing ", rv.files[p[2]], '\n')
                remove <<- c(remove, p[2])
                actions <- c(actions, str_join(rv.files[p[2]], '\t', resp))
            } else if (resp == 2) {
                cat("Removing ", rv.files[p[1]], '\n')
                remove <<- c(remove, p[1])
                actions <- c(actions, str_join(rv.files[p[1]], '\t', resp))
            } else if (resp == 'o') {
                actions <- c(actions, str_join(rv.files[p], '\t', resp))                
                browseURL(header(headers[[i]], 'nexsci_url'))
                next
            } else {
                actions <- c(actions, str_join(rv.files[p]), '\t', resp)
            }
            break
        }
        })

        remove <- unique(remove)
        if (length(remove) > 0) {
            for (rv.file in rv.files[remove]) {
                file.remove(rv.file)
                cat("Removing ", rv.file)
            }
            
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
    done <- c(done, sys.file)
    writeLines(done, 'done.txt')
    writeLines(actions, 'actions.txt')
}
