library(shiny)
library(httr2)
library(promises)

ui <- fluidPage(
  title = "Promise Example",
  plotOutput("plot")
)

url <- "https://ocw.mit.edu/courses/15-097-prediction-machine-learning-and-statistics-spring-2012/89d88c5528513adc4002a1618ce2efb0_iris.csv"

server <- function(input, output, session) {

  plot_data <- reactiveVal()

  observe({
    httr2::request(url) |>
      httr2::req_perform_promise() %...>%
      httr2::resp_body_string() %...>%
      read.csv(text = .) %...>%
      plot_data()
    return(NULL)
  })

  output$plot <- renderPlot({
    req(plot_data())
    plot(plot_data())
  })
}

shinyApp(ui, server)
