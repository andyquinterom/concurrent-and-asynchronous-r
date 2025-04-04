library(promises)
library(later)

mtcars_promise <- promise(\(res, rej) res(mtcars))
iris_promise <- promise(\(res, rej) res(iris))

mtcars_promise %...>%
  dplyr::glimpse() %...>%
  colnames() %...>%
  print()

iris_promise %...>%
  dplyr::glimpse() %...>%
  colnames() %...>%
  print()

# We force execution of the R code in the global `later`
# event loop
repeat {
  later::run_now()
}
