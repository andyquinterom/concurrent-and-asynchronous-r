library(shiny)
library(later)
library(promises)

time_promise <- function(time) {
  promise(function(res, rej) {
    current_date <- Sys.Date()
    input_datetime <- as.POSIXct(paste(current_date, time), format = "%Y-%m-%d %H:%M:%S")
    check_time <- function() {
      now <- Sys.time()
      if (now >= input_datetime) {
        res(now)
      } else {
        later::later(check_time, delay = 5)
      }
    }

    check_time()

  })
}

ui <- fluidPage(
  title = "Promise Example",
  textOutput("promise_output")
)

server <- function(input, output, session) {
  output$promise_output <- renderText({
    time_promise("19:00:00") %...>%
      as.character()
  })
}

shinyApp(ui, server)
