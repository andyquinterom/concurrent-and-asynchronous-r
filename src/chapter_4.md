# Integrating into Shiny

Before moving on to more complex and cool promises, let's take a step back and
build a Shiny app that shows the time on the screen only after 7 PM (or
whatever time you set). This is a simple example, but it will help us
understand how Shiny integrates with promises.

## Some context about Shiny and Promises

Shiny has an event loop. That's how it can be reactive and respond to user
inputs and events asynchronously. However, if the code we write inside a
Shiny app is not asynchronous it will block the event loop. Shiny will await
promises only when a renderer or an observer returns a promise. This piece of
context is crucial to understand, because if we don't take this into account
some unexpected behavior may happen.

## Promises as output

To not waste any time here is the code for the app. The code for the
`time_promise` function is the same as in the previous chapter. In this case
we will render the time as text once the `time_promise` is resolved.

```r
library(shiny)

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
```

As you can see, the last value of `renderText` is a promise. Remember that
`%...>%` chains promises, so our call to `as.character()` will be executed
in a promise.

If you run this code, you will see a blank screen until 7 PM. After that, the
time will be displayed. If you enter at any time after 7 PM, the promise will
immediately resolve and the time will be displayed.

This works because again, the last value of `renderText` is a promise. Shiny
is then smart enough to wait until the promise is resolved before displaying the
value.

This Shiny app is a simple example, but it is non-blocking, which means
that many users can use it at the same time and non would block the
application.

There is however one big caveat, the `renderText` does block the rest user's
local session. Since Shiny is basically awaiting the promise, no other code
can run in the same Shiny session. It does not block other users but it does
block the current session.

## Promises as observers

In the previous example we used `renderText` to display the time which blocks
the current session until the promise is resolved. Maybe we want this, and
usually we do, especially when rendering UI elements like text or plots. But
what if we want the user to still be able to fully interact with the app and
run our promise in the background? Well, we can use observers and leverage
reactivity.

Remember, Shiny will block the session if either a renderer or an observer
returns a promise. So we can use `observe` to run our promise in the
background aslong as it does not return the promise.

Let's write the same application but this time using `observe` instead of
`renderText` to run the promise.

```r
library(shiny)

ui <- fluidPage(
  title = "Promise Example",
  textOutput("promise_output")
)

server <- function(input, output, session) {

  time_when_resolved <- reactiveVal()

  observe({
    time_promise("19:00:00") %...>%
      as.character() %...>%
      time_when_resolved()
    return(NULL) # This is crucial
  })

  output$promise_output <- renderText({
    time_when_resolved()
  })
}

shinyApp(ui, server)
```

In this case, we are using `reactiveVal` to store the time when the promise
is resolved. The `observe` function will run the promise at the start of
the session, the only reason it does not block the session is because we
are return `NULL` at the end of the `observe`.

If we remove the `return(NULL)` the behavior will be practically the same
as the example with only `renderText`. The promise will block the session
until it is resolved.

This gives us some cool flexibility that we can use to for example, instead
of rendering the time, send a notification to the user.

```r
observe({
  time_promise("19:00:00") %...>%
    as.character() %...>%
    showNotification("The time is now: ", .)
  return(NULL) # This is crucial
})
```

## Using promises from other packages

Until now we have only used our own promise implementation. However,
some packages already have promise implementations. Let's create an example
for a Shiny app that fetches some data asynchronously from the web using `httr2`
and `promises`.

```r
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
```

In this example we leveraging `httr2` to asynchronously fetch a CSV file containing
the iris dataset. The `req_perform_promise` function will return a promise
that will be resolved once the request is completed. The rest of the code is
pretty similar to what we have seen already.

This is pretty cool because we are fetching data without blocking the R session,
which is a common challenge in Shiny apps. Other users can still interact with the
app while the data is being fetched.

## Conclusion

In this chapter we have seen how to integrate promises into Shiny apps. At this
point in the book you should be able to start using promises in your own Shiny
apps. If this is where you stop, I hope you have learned something new and that
you can start applying it in your own work today. You now have the tools you
need to start your async journey.

In the next chapters we will start looking at more use cases and building
promises that do more useful things than just waiting for time to pass.
