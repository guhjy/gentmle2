% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gentmle.R
\name{gentmle}
\alias{gentmle}
\title{gentmle}
\usage{
gentmle(initdata, params, submodel = submodel_logit, loss = loss_loglik,
  depsilon = 1e-04, approach = "full", max_iter = 100, g.trunc = 1e-04,
  Q.trunc = 1e-04, simultaneous.inference = FALSE, ...)
}
\arguments{
\item{initdata, }{dataframe with the following names: A is the treatment vector, Y is the outcome
Qk is the initial prediction for the outcome, Q1k is the initial prediction setting A to 1,
Q0k is the initial prediction for the outcome setting A = 0.  gk is the initial fit
for the treatment mechanism.}

\item{params, }{named list of parameters to estimate. See define_param for details}

\item{submodel, }{submodel along which to fluctuate}

\item{loss, }{loss function to optimize}

\item{depsilon, }{small epsilon, used for the recurisve approach only}

\item{approach, }{One of initial, recursive (small delta), line, full}

\item{max_iter, }{Maximum number of iteration steps. 100 is almost always more
than sufficient for full or line approach.  Try 10000 for recursive approach and
very occasionally you might need more.}

\item{g.trunc, }{To keep treatment mechanism probs between [g.trunc, 1 - g.trunc].
Prevents practical positivity violations from making highly variant estimates}

\item{Q.trunc, }{To keep outcome prediction probs between [Q.trunc, 1 - Q.trunc].
This prevents infinite loss in case of log-likelihood loss}
}
\description{
General TMLE function that takes care of the bookkeeping of estimation and update steps.
}
\examples{
###### Example of TMLE for the treatment-specific mean E[Y_1]

Qbar0 <- function(A, W) {
    W1 <- W[, 1]
    W2 <- W[, 2]
    Qbar <- plogis(A + A * W1 + W2)
    return(Qbar)
}

g0 <- function(W) {
    W1 <- W[, 1]
    W2 <- W[, 2]
    # rep(0.5, nrow(W))
    plogis(0.25 * W1 - 0.1 * W2)
}

gen_data <- function(n = 1000, p = 2) {
    W <- matrix(rnorm(n * p), nrow = n)
    colnames(W) <- paste("W", seq_len(p), sep = "")
    A <- rbinom(n, 1, g0(W))
    u <- runif(n)
    Y <- as.numeric(u < Qbar0(A, W))
    data.frame(W, A, Y)
}

data <- gen_data(1000)
Wnodes <- grep("^W", names(data), value = T)
gk <- g0(data[, Wnodes])
Qk <- Qbar0(data$A, data[, Wnodes])
Q1k <- Qbar0(1, data[, Wnodes])

initdata <- data.frame(A = data$A, Y = data$Y, gk = gk, Qk = Qk, Q1k = Q1k)
result <- gentmle(initdata = initdata, params = list(param_EY1), approach = "recursive")
print(result)

###### Example of TMLE for the average treatment effect

Qbar0 <- function(A, W) {
    W1 <- W[, 1]
    W2 <- W[, 2]
    Qbar <- plogis(A + A * W1 + W2)
    return(Qbar)
}

g0 <- function(W) {
    W1 <- W[, 1]
    W2 <- W[, 2]
    # rep(0.5, nrow(W))
    plogis(0.25 * W1 - 0.1 * W2)
}

gen_data <- function(n = 1000, p = 2) {
    W <- matrix(rnorm(n * p), nrow = n)
    colnames(W) <- paste("W", seq_len(p), sep = "")
    A <- rbinom(n, 1, g0(W))
    u <- runif(n)
    Y <- as.numeric(u < Qbar0(A, W))
    data.frame(W, A, Y)
}

data <- gen_data(1000)
Wnodes <- grep("^W", names(data), value = T)
gk <- g0(data[, Wnodes])
Qk <- Qbar0(data$A, data[, Wnodes])
Q1k <- Qbar0(1, data[, Wnodes])
Q0k <- Qbar0(0, data[, Wnodes])

# for 1 step TMLE a la Mark van der Laan's new work choose recursive approach with a lot
# of iterations
initdata <- data.frame(A = data$A, Y = data$Y, gk = gk, Qk = Qk, Q1k = Q1k, Q0k = Q0k)
result <- gentmle(initdata = initdata, params = list(param_ATE),
                  approach = "recursive", max_iter = 10000)
print(result)

# for iterative TMLE, choose full
result <- gentmle(initdata = initdata, params = list(param_ATE), approach = "full")
print(result)

###### Example of TMLE for variance of conditional average treatment effect or blip variance
###### var(E[Y|A=1, W] - E[Y|A=0, W])

Qbar0 <- function(A, W) {
    W1 <- W[, 1]
    W2 <- W[, 2]
    Qbar <- plogis(A + A * W1 + W2)
    return(Qbar)
}

g0 <- function(W) {
    W1 <- W[, 1]
    W2 <- W[, 2]
    # rep(0.5, nrow(W))
    plogis(0.25 * W1 - 0.1 * W2)
}

gen_data <- function(n = 1000, p = 2) {
    W <- matrix(rnorm(n * p), nrow = n)
    colnames(W) <- paste("W", seq_len(p), sep = "")
    A <- rbinom(n, 1, g0(W))
    u <- runif(n)
    Y <- as.numeric(u < Qbar0(A, W))
    data.frame(W, A, Y)
}

data <- gen_data(1000)
Wnodes <- grep("^W", names(data), value = T)
gk <- g0(data[, Wnodes])
Qk <- Qbar0(data$A, data[, Wnodes])
Q1k <- Qbar0(1, data[, Wnodes])
Q0k <- Qbar0(0, data[, Wnodes])

initdata <- data.frame(A = data$A, Y = data$Y, gk = gk, Qk = Qk, Q1k = Q1k, Q0k = Q0k)
result <- gentmle(initdata = initdata, params = list(param_sigmaATE), approach = "recursive")
print(result)

# for iterative TMLE, choose full--different approaches sometimes give slightly
# different answers
result <- gentmle(initdata = initdata, params = list(param_sigmaATE), approach = "full")
print(result)

###### Example of TMLE for simultaneous estimation of two parameters,
###### ATE and blip variance

# notice here we specify two parameters to be simultaneously estimated
initdata <- data.frame(A = data$A, Y = data$Y, gk = gk, Qk = Qk, Q1k = Q1k, Q0k = Q0k)
result <- gentmle(initdata = initdata, params = list(param_ATE, param_sigmaATE),
                  approach = "recursive", max_iter = 10000)
print(result)

# for iterative TMLE, choose full--different approaches sometimes give slightly
# different answers

# full approach computes a separate epsilon for each parameter
result <- gentmle(initdata = initdata, params = list(param_ATE, param_sigmaATE),
                  approach = "full")
print(result)

# line approach is the iterative analog of the 1 step TMLE
result <- gentmle(initdata = initdata, params = list(param_ATE, param_sigmaATE),
                  approach = "line")
print(result)

# recursive is the 1 step tmle as in Mark van der Laan's recent work
result <- gentmle(initdata = initdata, params = list(param_ATE, param_sigmaATE),
                  approach = "recursive", max_iter = 10000)

# One can also form simultaneous confidence bounds for numerous params using the
# influence curves by specifying simultaneous.inference = TRUE

result <- gentmle(initdata = initdata, params = list(param_ATE, param_sigmaATE),
                  approach = "recursive", max_iter = 10000, simultaneous.inference = TRUE)
print(result)


}
