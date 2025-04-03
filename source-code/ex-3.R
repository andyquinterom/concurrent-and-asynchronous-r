library(promises)
library(later)

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

time_promise("16:47:00") %...>%
  print()

repeat {
  later::run_now()
}
