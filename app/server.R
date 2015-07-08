library(shiny)

shinyServer(function(input, output) {

  output$text <- renderPrint({input$tabs})
  dataset <- reactive({
    switch(input$tabs,
           combined=readRDS('combined_star_data.rds'))
  })
  
  output$table <- renderDataTable({ dataset() })
})
