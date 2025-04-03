# Getting our feet wet with async R

R does not natively support async programming. Languages like Python, Rust or
JavaScript have built-in asynchronous primitives that allow us to write
asynchronous code.

An example of async code in Python is:

```python
async def my_function():
    await some_other_function()
```

You can see that the function is defined with the `async` keyword and that it
is calling another function with the `await` keyword. This means that at
a language level, we are setting a difference between a normal function and
an asynchronous function.

This also applies to Rust and JavaScript - they have special syntax for
defining what is async and what is not.

In R, we don't have this. I wish we had, but we don't at the time of writing
this book. Therefore, we need to leverage libraries like `later` and `promises`
that give us the primitives to write async code. Thankfully, R has some
pretty solid meta-programming capabilities which means we these libraries
provide some syntax that help us get closer to the natively supported async
in other languages.

## The `later` package

The `later` package is a library that allows us to run R functions later. The
name is therefore quite self-explanatory.

`later` provides the ability to schedule R functions for later execution, that
can then be invoked by an event loop. We will look into what an event loop later
on but for now, just think of it as the master function that decides what and
when to run the scheduled functions.

The `later` package is a basic primitive for writing our async R code. Everything
we do asynchronously will need to be scheduled using `later`.

## The `promises` package

The `promises` package is the library that brings the async programming model to R.
It provides the `promise` object that allows us to define the asynchronous tasks
we want to run.

It also provides the `then` and `%...>%` functions which work similarly to the 
`await` keyword in other languages.

Later on we will learn how to create custom promises and how to leverage
them in Plumber and Shiny.

## How async code runs

In a very reduced way, async code runs however the event loop decides to run it.
This can vary widely between implementations. For example, the async runtime
`tokio` in Rust uses an event loop along side thread pool to run async tasks,
which means that it is mostly non-deterministic. The JavaScript runtime uses
a single-threaded event loop that runs tasks from a queue.

In R, the `later` package provides a single-threaded event loop that runs tasks
in a queue. This means that tasks run in whatever order they are scheduled.

We will not dive into the details of how to implement the following example,
we will get into that in a later (pun intended) chapter. For now, just try to
guess how to output of the following R code will look like:

```r
mtcars_promise %...>%
  dplyr::glimpse() %...>%
  colnames() %...>%
  print()

iris_promise %...>%
  dplyr::glimpse() %...>%
  colnames() %...>%
  print()
```

If you have used R for a while, you probably guessed that the output would look
like this:

```
#> Rows: 32
#> Columns: 11
#> $ mpg  <dbl> 21.0, 21.0, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, 22.8, 19.2, 17.8,…
#> $ cyl  <dbl> 6, 6, 4, 6, 8, 6, 8, 4, 4, 6, 6, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 8,…
#> $ disp <dbl> 160.0, 160.0, 108.0, 258.0, 360.0, 225.0, 360.0, 146.7, 140.8, 16…
#> $ hp   <dbl> 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180, 180…
#> $ drat <dbl> 3.90, 3.90, 3.85, 3.08, 3.15, 2.76, 3.21, 3.69, 3.92, 3.92, 3.92,…
#> $ wt   <dbl> 2.620, 2.875, 2.320, 3.215, 3.440, 3.460, 3.570, 3.190, 3.150, 3.…
#> $ qsec <dbl> 16.46, 17.02, 18.61, 19.44, 17.02, 20.22, 15.84, 20.00, 22.90, 18…
#> $ vs   <dbl> 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,…
#> $ am   <dbl> 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0,…
#> $ gear <dbl> 4, 4, 4, 3, 3, 3, 3, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 4, 3, 3,…
#> $ carb <dbl> 4, 4, 1, 1, 2, 1, 4, 2, 2, 4, 4, 3, 3, 3, 4, 4, 4, 1, 2, 1, 1, 2,…
#> [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
#> [11] "carb"
#> Rows: 150
#> Columns: 5
#> $ Sepal.Length <dbl> 5.1, 4.9, 4.7, 4.6, 5.0, 5.4, 4.6, 5.0, 4.4, 4.9, 5.4, 4.…
#> $ Sepal.Width  <dbl> 3.5, 3.0, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, 3.1, 3.7, 3.…
#> $ Petal.Length <dbl> 1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, 1.4, 1.5, 1.5, 1.…
#> $ Petal.Width  <dbl> 0.2, 0.2, 0.2, 0.2, 0.2, 0.4, 0.3, 0.2, 0.2, 0.1, 0.2, 0.…
#> $ Species      <fct> setosa, setosa, setosa, setosa, setosa, setosa, setosa, s…
#> [1] "Sepal.Length" "Sepal.Width"  "Petal.Length" "Petal.Width"  "Species"     
```

In the output above we see first the glimpse of the `mtcars` dataset and then the
the columns names of the same dataset. Then we see the glimpse of the `iris` dataset and
then the column names of the same dataset. This is intuitively what we would expect -
when you run code you expect the output to be in the same order as the code.
However, in reality, the output looks like this:

```
#> Rows: 32
#> Columns: 11
#> $ mpg  <dbl> 21.0, 21.0, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, 22.8, 19.2, 17.8,…
#> $ cyl  <dbl> 6, 6, 4, 6, 8, 6, 8, 4, 4, 6, 6, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 8,…
#> $ disp <dbl> 160.0, 160.0, 108.0, 258.0, 360.0, 225.0, 360.0, 146.7, 140.8, 16…
#> $ hp   <dbl> 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180, 180…
#> $ drat <dbl> 3.90, 3.90, 3.85, 3.08, 3.15, 2.76, 3.21, 3.69, 3.92, 3.92, 3.92,…
#> $ wt   <dbl> 2.620, 2.875, 2.320, 3.215, 3.440, 3.460, 3.570, 3.190, 3.150, 3.…
#> $ qsec <dbl> 16.46, 17.02, 18.61, 19.44, 17.02, 20.22, 15.84, 20.00, 22.90, 18…
#> $ vs   <dbl> 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0,…
#> $ am   <dbl> 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0,…
#> $ gear <dbl> 4, 4, 4, 3, 3, 3, 3, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 4, 3, 3,…
#> $ carb <dbl> 4, 4, 1, 1, 2, 1, 4, 2, 2, 4, 4, 3, 3, 3, 4, 4, 4, 1, 2, 1, 1, 2,…
#> Rows: 150
#> Columns: 5
#> $ Sepal.Length <dbl> 5.1, 4.9, 4.7, 4.6, 5.0, 5.4, 4.6, 5.0, 4.4, 4.9, 5.4, 4.…
#> $ Sepal.Width  <dbl> 3.5, 3.0, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, 3.1, 3.7, 3.…
#> $ Petal.Length <dbl> 1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, 1.4, 1.5, 1.5, 1.…
#> $ Petal.Width  <dbl> 0.2, 0.2, 0.2, 0.2, 0.2, 0.4, 0.3, 0.2, 0.2, 0.1, 0.2, 0.…
#> $ Species      <fct> setosa, setosa, setosa, setosa, setosa, setosa, setosa, s…
#>  [1] "mpg"  "cyl"  "disp" "hp"   "drat" "wt"   "qsec" "vs"   "am"   "gear"
#> [11] "carb"
#> [1] "Sepal.Length" "Sepal.Width"  "Petal.Length" "Petal.Width"  "Species"     
```

What? You might be asking. Why do we see the glimpse of the `mtcars` dataset
then the glimpse of the `iris` dataset and then the column names of the `mtcars`
dataset followed by those of the `iris` dataset? This is not even close to
the code we wrote.

Remember, when writing async code, the order of execution is not necessarily
sequential. Let's disect the code a bit to understand why the output looks like
this.

## Understanding how promises are scheduled

Before we get into the details of why code was executed in this order,
let's understand what the `%...>%` operator does.

The `%...>%` is syntax sugar for the `then` function. The then function takes
a `promise` and schedules a function to be executed once the input promise
is resolved. Again, we will dive deeper into what resolving a promise means
later on, but for now it just means that the promise is ready to return a value.

Remember that the `later` event loop is a single-threaded event loop that runs
tasks in a queue (meaning that they run in the order they are scheduled unless
a delay is present).

Given this, let's take a look a look at the code again and try to see
where the scheduling happens.

```r
mtcars_promise %...>% # 1. Schedules dplyr::glimpse() to run once mtcars_promise is resolved
  dplyr::glimpse() %...>% # The rest of this pipeline does not run yet
  colnames() %...>%
  print()

iris_promise %...>% # 2. Schedules dplyr::glimpse() to run once iris_promise is resolved
  dplyr::glimpse() %...>% # The rest of this pipeline does not run yet
  colnames() %...>%
  print()
```


The first line of the code runs immediately and registers the scheduled function
`dplyr::glimpse()` to run once the promise `mtcars_promise` is resolved. The
rest of the pipeline is not scheduled yet, since the `dplyr::glimpse()` promise
is not yet resolved. When we move on to the next pipeline, the same thing happens
but for the `iris_promise` instead.

This explains why we see the glimpse of the `mtcars` dataset first and then the glimpse
of the `iris` dataset. The event loop has a queue of tasks that look like this:

```
1 [mtcars_promise]
2 [iris_promise]
3 [dplyr::glimpse()] # For mtcars_promise
4 [dplyr::glimpse()] # For iris_promise
```

Once the `dplyr::glimpse()` runs for `mtcars_promise` a new task is added to
the queue:

```
* [mtcars_promise]
* [iris_promise]
* [dplyr::glimpse()] # For mtcars_promise
1 [dplyr::glimpse()] # For iris_promise
2 [colnames()] # For mtcars_promise
```

Once the `dplyr::glimpse()` runs for `iris_promise` a new task is added to
the queue:

```
* [mtcars_promise]
* [iris_promise]
* [dplyr::glimpse()] # For mtcars_promise
* [dplyr::glimpse()] # For iris_promise
1 [colnames()] # For mtcars_promise
2 [colnames()] # For iris_promise
```

And so on until the queue is empty and no more tasks are scheduled. The full
queue would look like this:

```
1 [mtcars_promise]
2 [iris_promise]
3 [dplyr::glimpse()] # For mtcars_promise
4 [dplyr::glimpse()] # For iris_promise
5 [colnames()] # For mtcars_promise
6 [colnames()] # For iris_promise
7 [print()] # For mtcars_promise
8 [print()] # For iris_promise
```

This reflects the order of our output to the console. Now we understand why
it happens this way. This will make more sense once we learn how to build
our own custom promises.

Note that some promises may schedule hundreds of tasks to run in the event loop,
in this case the number of tasks are small and easy to follow. But in a real
world scenario, it might be difficult if not humanly impossible to follow.

This is an example of _concurrent_ but not _parallel_ code. You can see that both
tasks, the pipeline for `mtcars` and `iris` both run together but not in parallel -
one part of the process runs, then yields to the other part of the process and
back and forth until the queue is empty.

In the next chapter we will learn how to build our own custom promises which
will likely make this a bit clearer.
