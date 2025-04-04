# An introduction to concurrency in R

Writing concurrent code in R is not natively supported. R is a single-threaded
language (we will get into what that really means later). However, R is mostly
written in C and Fortran, and many libraries are written in C++ and now Rust,
which means we can take full advantage of the concurrency features of the
operating system and the underlying languages like C++ and Rust.

In this book, we will explore how to write concurrent code that we can
integrate into R. We will learn how Shiny and Plumber use asynchronous
execution out of the box and how we can write custom concurrent
tasks. We will learn patterns for data loading like streaming and how to use
them in operations like training machine learning models.

This book will make use of Rust for writing concurrent-parallel code that
runs in the same memory space as R. This does not mean that all concurrent code
in the book will be written in Rust, we will also take a look at how to leverage
cloud computing to run cocurrent R code in the cloud.

## What is concurrency?

Concurrency, asynchrony, parallelism are all terms that are often used
interchangeably without a clear understanding of what they mean. They are not
the same thing, but they are related and not mutually exclusive.

### Concurrency

Concurrency is the, at its core, the ability to run multiple tasks together.
Not necessarily in parallel, but together. This means the execution
could be interleaved using a single thread (this is usually the case in languages
like JavaScript) or it could be truly parallel using multiple CPU cores, or
even in multiple servers across the world.

### Parallelism

Parallelism is the ability to run multiple tasks at the same time. Notice the difference?
At the same time means that at a certain point in time both tasks are running.
In concurrency, tasks can be interleaved, which means that they are not
necessarily running at the same time, but running together one yielding to the other.
Parallelism is a form of concurrency, but not all concurrency is parallelism.

### Asynchrony

This is probably the trickiest term to understand. This relates more to how
tasks are scheduled and executed. Most programming is done synchronously, which means
one line of code (or instruction) is executed one after the other. Even if we
are running concurrently, we are still executing instructions one after the other.

Asynchronous (or async) programming is a way to write code that allows a task
to be scheduled to run concurrently with other tasks. We can absolutely write
async code that seems syncronous, even if it is not.

Async code can be parallel, or not. It can be concurrent, or not. It is just
a way to write code that allows us to control the flow of execution. This is
extremely useful when we want to write concurrent code because it abstracts
many of the details that make writing concurrent code difficult.

The main goal of async programming is to allow us to write code that does
not block the execution of other code (at least not for very long). This means
we can a server that can handle multiple requests concurrently, or a shiny
app that can handle many users at the same time, or a data loading function
that can load data in the background while we are leveraging the GPU to
train a model.

## What's coming next?

In the next chapter, we will start exploring asynchronous programming in R
using `later` and `promises`. We will try to dissect the differences between
interleaving tasks and running them in parallel with practical examples.
