# Pulls RV data from the Exoplanet Archive.
require(stringr)
wait <- 2

if (!exists('plhost.downloaded'))
    plhost.downloaded <- c()

planets.table <- function() {
    table <- read.csv(url("http://exoplanetarchive.ipac.caltech.edu/cgi-bin/nstedAPI/nph-nstedAPI?table=exoplanets"))
    table <- cbind(table, read.csv(url("http://exoplanetarchive.ipac.caltech.edu/cgi-bin/nstedAPI/nph-nstedAPI?table=exoplanets&select=st_nrvc")))
    return(table)
}

prop.mangling <- list(
    TELESCOPE = c(KECK="KECK", AAT="AAT", LICK="LICK", SHANE="LICK", HET="HET",
        TAUTENBERG="TAUTENBERG", JENSCH="JENSCH", CFHT="CFHT", HJS="HJS", ESO="ESO",
        MCDONALD="MCDONALD", KUEYEN="VLT", EULER="EULER", SUBARU="SUBARU", MAGELLAN="MAGELLAN",
        TILLINGHAST="TILLINGHAST", ANGLO="AAT", NOT="NOT")       
)

props <- c(
    "STAR_ID",
    "TELESCOPE",
    "REFERENCE",
    "BIBCODE",
    "INSTRUMENT",
    "WAVELENGTH_CALIBRATION_TECHNIQUE",
    "TELESCOPE"
)

extract.prop <- function(tbl.lines, property, mangle=FALSE) {
    
    line <- toupper(tbl.lines[str_detect(tbl.lines, str_join("\\\\", property))])
    if (length(line) == 0)
        return(NA)
    
    value <- str_match(line, "\"(.+)\"")
    if (is.na(value))
        return(NA)
    value <- value[,2]
    
    if (mangle && property %in% names(prop.mangling)) {
        prop.list <- toupper(prop.mangling[[property]])
        which <- str_detect(value, toupper(names(prop.list)))
        if (any(which))
            value <- prop.list[[which(which)[1]]]
        else
            warning(value)
    }
    
    return(value)
}

create.db <- function(table) {
    table <- table[table$st_nrvc > 0, ]

    data.url <- "http://exoplanetarchive.ipac.caltech.edu/cgi-bin/ExoOverview/nph-ExoOverview?objname=%s&label&aliases&exo&orb&ppar&tran&disc&ospar&ts&type=CONFIRMED_PLANET"
    table.url <- "http://exoplanetarchive.ipac.caltech.edu/"
    
    apply(table, 1, function(row) {
        if (row['pl_hostname'] %in% plhost.downloaded)
            return()

        host <- str_replace_all(row['pl_hostname'], " ", "")
        
        cat('Downloading ', row['pl_hostname'], '...')
        conn <- url(sprintf(data.url, URLencode(str_join(row['pl_hostname'], ' ', row['pl_letter']))))
        string <<- str_join(readLines(conn), collapse="\n")
        close(conn)
        
        tbl.urls <- str_match_all(string, "href=(/.+?tbl)")[[1]][,2]
        tbl.urls <- tbl.urls[str_detect(tbl.urls, "RVC")]
        tbl.urls <- str_join(table.url, tbl.urls)
        cnt <- 1

        rvs <- c()

        sys <- file(sprintf("%s.sys", host), "w")
        cat(file=sys, sprintf("# Data from %s\n\n", table.url))
        cat(file=sys, sprintf("Name\t%s\nMass\t%s\nHD\t%s\nHIP\t%s\nTeff\t%s\nRA\t%s\nDec\t%s\n\n",
                row['pl_hostname'],
                if (is.na(row['pl_stmass'])) 1 else row['pl_stmass'],
                row['hd_name'],
                row['hip_name'],
                row['st_teff'],
                row['ra'],
                row['dec']))
            
        
        for (tbl.url in tbl.urls) {

            tbl.conn <- url(tbl.url)
            lines <- readLines(tbl.conn)
            close(tbl.conn)

            data <- lines[(! str_detect(lines, "\\\\")) & (! str_detect(lines, "\\|"))]
            
            telescope <- extract.prop(lines, "TELESCOPE")
            telescope.code <- extract.prop(lines, "TELESCOPE", mangle=TRUE)
            reference <- extract.prop(lines, "REFERENCE")
            bibcode <- extract.prop(lines, "BIBCODE")
            instrument <- extract.prop(lines, "INSTRUMENT")
            observatory <- extract.prop(lines, "OBSERVATORY_SITE")
            
            fn <- sprintf("%s_%d_%s.vels",
                         host,
                         cnt,
                         str_replace_all(telescope.code, " ", "_"))

            f <- file(fn, "w")
            cat(file=f, sprintf("# telescope = %s\n", telescope))
            cat(file=f, sprintf("# instrument = %s\n", instrument))
            cat(file=f, sprintf("# observatory = %s\n", observatory))
            cat(file=f, sprintf("# reference = %s\n", reference))
            cat(file=f, sprintf("# bibcode = %s\n", bibcode))
            cat(file=f, sprintf("# source = %s\n", tbl.url))
            cat(file=f, data, sep="\n")
            
            cnt <- cnt+1
            close(f)
            rvs <- c(rvs, fn)
            cat(file=sys, sprintf("RV[]\t%s\n", fn))
        }
        plhost.downloaded <<- c(plhost.downloaded, row['pl_hostname'])
        close(sys)
        Sys.sleep(wait)
    })
    
}
