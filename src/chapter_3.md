# Writing a Promise

Now that we understand that async code does not always run in the order
we write it and have a high-level understanding of how the code is executed
we can get into actually writing a Promise.

So, what is a Promise? Even though we have already seen a few examples and
a high level definition of a Promise, we have not yet defined it in a formal way.

A Promise is an object (when talking about R, JavaScript, Python, etc.) that
represent a value that may not be available yet. Every language has its own
way of implementing a Promise, in Rust for example, a Promise (or Future) is a
struct that implements the `Future` trait. This trait has a method called `poll`
that a scheduler (like an event loop) can call to check if the value is ready.

In R, a promise is an object that has two callback functions `resolve` and `reject`.
The object can be chained with other promises by using functions like `then` or
the `%...>%` as we saw in the previous chapter.

## My first Promise

Let's create a promise that resolves immediately. To create a promise we
need to use the `promises::promise` function. The `promise` function takes
a function with two arguments, `resolve` and `reject` (which are themselves
functions). The `resolve` function is called when the promise has resolved, while
the `reject` function is called when the promise has rejected (or errored).

So... let's create the `mtcars_promise` from last chapter's example.

```r
library(promises)
library(later)

mtcars_promise <- promise(\(res, rej) res(mtcars))
```

As you can see, we call the `promise` function. We pass in the function that
will run the promise with its respective `res` and `rej` arguments.

Since we want our promise to resolve immediately, we call the `res` function with
`mtcars` as the argument. This will create a promise that resolves the moment
it is created.

This is useful if we want to create a promise that we can then chain with other
promises, but typically we want to create a promise that represents something
that has not happened yet.

Before building a promise that does something more useful, let's see how we can
create a promise that returns a value later.

Let's take the code we already have and add a call to `later::later` to
schedule an event to resolve later.

```r
mtcars_promise <- promise(function(res, rej) {
  later::later(\() res(mtcars), delay = 1)
})
```

In this case, we create a promise in the same way as before. However,
this promise now schedules a task in the event loop to resolve the promise
after 1 second. Remember how scheduling allowed us to run code interleaved
with other code? This is not full asynchronous code. We should be able to create
multiple promises and have them run concurrently.

## A Promise for time

Now that we have created a promise that resolves after 1 second, we can start
bootstrapping our knowledge to build more complex promises. Let's build a promise
that resolves once the system clock hits a certain time.

This is a very theoretical example, but image something like a Shiny app
that you want to change to dark mode at 6:00 PM. You may say, "What if I
just check for this at the start of the app?" While this is valid, what if
a user opens the app at 5:55 and leaves it open? We could use some sort
of reactive programming to check for this, however this may be more expensive
computationally than just waiting.

So, how do we go about building such a promise? Well, we need to ask ourselves
a question: How often do we want to check the time? We could absolutely check
every millisecond, but that seems wasteful. We could check every minute? Every
second maybe? This is a tradeoff, and for such a simple task like checking the
time it is probably not worth bugging about. If we needed such a precise
time promise, maybe R is not the tool for the job. So, let's settle for every
5 seconds.

There is one additional caveat to how promises work. Tasks may be executed
asynchronously but R code itself is not. Unlike Rust, we don't have such
a tight control over the execution of code. Meaning, if we do something
like a for loop, we will block the event loop until the for loop is done.
This does not mean a for loop cannot schedule tasks to run later, it just
means that an iteration of the loop cannot be interrupted by the event loop.
This means that to poll the time we will need to use a recursive function.
Since every call to a function can be setup as a task in the event loop,
we can use this to our advantage.

```r
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
```

Ok, that's a lot of code. Let's break it down step by step.

1. We create a function called `time_promise` that takes a time as an argument.
2. We create a promise that takes a function with `res` and `rej` as arguments.
3. We create `input_datetime` by combining the current date with the time we want to check.
4. We create a function called `check_time` that checks if the current time
   is greater than or equal to the input time.
5. If it is, we resolve our promise with the current time, if not it will schedule
   (using `later::later`) itself to run again in 5 seconds. This is the recursive part.
6. We call the `check_time` function to start the process.

The curious thing about his pattern is that we have a funcion that
calls itself recursively, not how we would normally do it, but by
scheduling itself to run later.

This is weird, but it makes sense and is basically how all R packages
that take advantage of promises work.

## Taking a look at the `httr2` package

The following code is from the `httr2` package which implements a way of
making asynchronous HTTP requests. The code is a bit more complex than
the one we just saw, but it is the same idea. It calls the `poll_pool` function
which is a recursive function that checks the status of the request. If
it is not done, it schedules itself to run again in 0 seconds, else it
calls the `ending` function.

```r
ensure_pool_poller <- function(pool, reject) {
  monitor <- pool_poller_monitor(pool)
  if (monitor$already_going()) return()

  poll_pool <- function(ready) {
    tryCatch(
      {
        status <- curl::multi_run(0, pool = pool)
        if (status$pending > 0) {
          fds <- curl::multi_fdset(pool = pool)
          later::later_fd(
            func = poll_pool,
            readfds = fds$reads,
            writefds = fds$writes,
            exceptfds = fds$exceptions,
            timeout = fds$timeout
          )
        } else {
          monitor$ending()
        }
      },
      error = function(cnd) {
        monitor$ending()
        reject(cnd)
      }
    )
  }

  monitor$starting()
  poll_pool()
}
```

You may be wondering where is the `resolve` function in this code. Well,
that `pool` object is an object that at another point receives the `resolve`
function. Since these are specific to the `httr2` package, they are not
completely relevant to us, but if you are curious this is how it looks.

```r
promises::promise(function(resolve, reject) {
  pooled_req <- pooled_request(
    req = req,
    path = path,
    on_success = function(resp) resolve(resp),
    on_failure = function(error) reject(error),
    on_error = function(error) reject(error)
  )
  pooled_req$submit(pool)
  ensure_pool_poller(pool, reject)
})
```

## Rewinding

We have now taken a look at how to create a promise and how we can use
it to represent something that will eventually happen.

We now understand how a promise schedules work to constantly check for
the status of a task, both in our time promise and in the `httr2` package.

Now that we have a solid base on how to build a promise, we can start
building more complex and useful promises.
