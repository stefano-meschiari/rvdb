require(stringr)

tbl <- function(t) {
    return(apply(t, 1, function(row) {
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
