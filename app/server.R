library(shiny)
library(DT)
library(stringr)
library(dplyr)
library(ggplot2)


`%~%` <- str_detect
theme_set(theme_gray(base_size=18))

theme_update(axis.title.x = element_text(vjust=0), axis.title.y = element_text(vjust=1, angle=90))

name_match <- function(string, pattern) {
  return(str_detect(str_to_upper(str_replace_all(string, ' ', '')),
                    fixed(str_to_upper(str_replace_all(pattern, ' ', '')))))
}

combined_db <- readRDS('combined_star_data.rds') %>%
  select(-fn) %>%
  mutate(name=str_c("<button class='btn btn-default star' onClick=javascript:starClick(this)>", name, '</button>'))

full_db <- readRDS('all_data.rds')

star <- function(input, output, session) {
  dataset <- reactive({
    full_db[[input$star]]
  })
  
  output$rvs <- renderDataTable({ datatable(dataset()$data,
                                           options=list(pageLength=5000, digits=3),
                                           filter='top') })

  output$plot_rvs <- renderPlot({
    
    data <- if (is.null(input$rvs_rows_all))
      dataset()$data
    else
      dataset()$data[input$rvs_rows_all, ]
    
    ggplot(data) +
      geom_point(aes(x=time, y=rv, color=telescope), size=4) +
      geom_errorbar(aes(x=time, ymin=rv-error, ymax=rv+error, color=telescope)) +
      xlab("Time [JD]") +
      ylab("RV [m/s]")
    
  })

  output$plot_periodogram <- renderImage({
    list(src=str_c('www/img/periodograms/', str_replace_all(input$star, " ", ""),
                   '.sys.png'), width=600, height=400)
  }, deleteFile=FALSE)

  output$periodogram <- renderTable({
    data <- as.data.frame(dataset()$periodogram)
    data[,'period'] <- sprintf("%.2f", data[,'period'])
    data[,'power'] <- sprintf("%.2f", data[,'power'])
    
    data[, 'fap'] <- str_c(str_replace(sprintf("~ %.2e", data[,'fap']), "e", "x10^"))
    setNames(data,
                    c('period', 'power', 'false alarm probability'))
  })

  output$info <- renderTable({ dataset()$props })
  output$datasets <- renderText({ str_c(sapply(dataset()$sets, function(n) str_c(n$fn, '\n', n$header, '\n\n')), collapse='')} )
}

all_stars <- function(input, output, session) {

  dataset <- reactive({
    db <- combined_db
    
    if (str_detect(input$search, '[\\(\\)\\{\\}\\[\\]]'))
      stop()
    
    if (str_trim(input$search) == "")
      db
    else if (!str_detect(input$search, '[=><%]')) {
      db <- db %>% filter(name_match(name, input$search) | name_match(hd, input$search))
    }
    else {
      tryCatch({
        s <- str_replace_all(input$search, "\\~", "%~%")
        print(s)
        p <- eval(parse(text=str_c("~ ", s)))
        filter_(db, p)
      }, error=function(e) { print(e); db })
    }    
  })
  
  plotSubset <- reactive({
    db <- dataset()
    x <- input$x_axis
    gby <- input$group_by
    if (! x %in% names(db))
      return(NULL)
    
    if (input$plot_type == 'Histogram') {
      if (str_trim(gby) == "" || ! gby %in% names(db)) {
        df <- data.frame(x=db[[x]], g = 0)
        p <- qplot(x, data=df, xlab=str_to_title(x), ylab='Count')
      } else {
        df <- data.frame(x=db[[x]], g = db[[gby]])
        fac <- as.factor(df$g)
        if (nlevels(fac) > 5) {
          df$g <- cut_number(df$g, 5)
        } else {
          df$g <- fac
        }
        p <- qplot(x, data=df, fill=g, xlab=str_to_title(x), ylab='Count') +
          guides(fill=guide_legend(title=gby)) 
        
      }
    } else if (input$plot_type == 'Scatter plot') {
      y <- input$y_axis
      if (! y %in% names(db))
        return(NULL)
      if (str_trim(gby) == "" || ! gby %in% names(db)) {
        df <- data.frame(x=db[[x]], y=db[[y]], g = 0)
        p <- qplot(x, y, data=df, xlab=str_to_title(x), ylab=str_to_title(y), size=I(4))
      } else {
        df <- data.frame(x=db[[x]], g = db[[gby]], y=db[[y]])
        fac <- as.factor(df$g)
        if (nlevels(fac) > 5) {
          df$g <- cut_number(df$g, 5)
        } else {
          df$g <- fac
        }

        p <- qplot(x, y, data=df, xlab=str_to_title(x), color=g, ylab=str_to_title(y), size=I(4)) +
          guides(fill=guide_legend(title=gby)) 
      }
    }
    return(p)
  })
  
  output$table <- renderDataTable(datatable({ dataset() }, escape=FALSE, selection='none'))
  output$plot <- renderPlot({ print(plotSubset()) })
  
}


shinyServer(function(input, output, session) {
  all_stars(input, output, session)
  star(input, output, session)
})
