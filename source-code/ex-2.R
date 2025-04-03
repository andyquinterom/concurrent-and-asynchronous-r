library(later)
library(promises)

mtcars_promise <- promise(function(res, rej) {
  later::later(\() res(mtcars), delay = 1)
})
