systemic.par$mar <<- c(0, 0, 0, 0)
plotPeriodogram <- function(f) {
  fn <- basename(f)
  plotfn <- str_c('../app/www/img/periodograms/', fn, '.png')
  
  k <- knew()
  kload.system(k, f)
  d <- kperiodogram(k)
  if (! any(is.nan(d[,2]))) {
    
    plot(d)
    quartz.save(plotfn, dpi=200,
                width=6, height=4)
  }
  return(d)
}
