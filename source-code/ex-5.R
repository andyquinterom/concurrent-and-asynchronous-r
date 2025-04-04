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

library(shiny)

ui <- fluidPage(
  title = "Promise Example"
)

server <- function(input, output, session) {

  time_when_resolved <- reactiveVal()

  observe({
    time_promise("19:00:00") %...>%
      as.character() %...>%
      showNotification("The time is now: ", .)
    return(NULL) # This is crucial
  })

}

shinyApp(ui, server)
