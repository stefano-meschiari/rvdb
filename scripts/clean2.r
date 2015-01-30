require(stringr)
source('common.r')

sys.files <- Sys.glob("*.sys")
vels <- unlist(sapply(sys.files, function(f) {
    lines <- readLines(f)
    rv.lines <- lines[str_detect(lines, "RV\\[\\]")]
    rv.files <- str_match(rv.lines, "\t(.+)")[,2]
    return(rv.files)
}))

vels2 <- Sys.glob("*.vels")
for (v in vels2) {
    if (! v %in% vels)
        file.remove(v)
}
