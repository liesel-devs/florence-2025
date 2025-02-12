
# setwd("C:/arbeit/talks/Madrid2024/practicals")

# read the data
dat <- read.table("data/linreg.dat", header=TRUE)

# plot and add the regression line from lm
plot(dat$x, dat$y, xlab="x", ylab="y")
abline(lm(y~x, data=dat))

# function for computing the log-posterior (the same as in Ex. 2)
log_posterior <- function(beta, y, x, sigma, prior_mean, prior_sd) {
    # current mean vector of the observation model
    mu <- beta[1] + beta[2] * x
    
    # log-likelihood
    log_lik <- sum(dnorm(y, mean = mu, sd = sigma, log = TRUE))
    
    # prior (since beta[1] has a constant prior, we only need the prior for beta[2] here)
    log_prior <- dnorm(beta[2], mean = prior_mean, sd = prior_sd, log = TRUE)
    
    # return the (un-normalized) log-posterior
    return(log_lik + log_prior)
}

# IWLS acceptance step
mh_step_iwls <- function(beta_proposed, beta_current, y, x, sigma, prior_mean, prior_sd, Finv) {
    
    X <- cbind(1, x)
    
    # compute log-posterior at proposed value
    log_prob_proposal <- log_posterior(
        beta_proposed,
        y,
        x,
        sigma,
        prior_mean,
        prior_sd
    )
    
    # compute log-posterior at current value
    log_prob_current <- log_posterior(
        beta_current,
        y,
        x,
        sigma,
        prior_mean,
        prior_sd
    )
    
    # log-densities of the proposal density
    sval_backward <- s_fn(y, X, beta_proposed, sigma, prior_sd)
    backward_mean <- beta_proposed + drop(Finv  %*% sval_backward)
    
    log_prob_backward <- mvtnorm::dmvnorm(
        beta_current,
        mean = backward_mean,
        sigma=Finv,
        log=TRUE
    )
    
    sval_forward <- s_fn(y, X, beta_current, sigma, prior_sd)
    forward_mean <- beta_current + drop(Finv  %*% sval_forward)
    
    log_prob_forward <- mvtnorm::dmvnorm(
        beta_proposed,
        mean = forward_mean,
        sigma=Finv,
        log=TRUE
    )
    
    # log-acceptance probability
    log_alpha_star <- log_prob_proposal - log_prob_current + log_prob_backward - log_prob_forward
    log_acceptance_prob <- min(0, log_alpha_star)
    
    # determine acceptance by comparing to a log-uniform
    accept <- log(runif(n = 1)) <= log_acceptance_prob
    
    if(accept) {
        beta_step <- beta_proposed
    } else {
        beta_step <- beta_current
    }
    
    # return the new state of the MCMC chain and whether acceptance took place
    return(list(beta = beta_step, accepted = accept))
}


# functions for IWLS proposal for beta
s_fn <- function(y, X, beta, sigma, prior_sd) {
    (t(X) %*% y - crossprod(X) %*% beta) / (sigma^2) - c(0, (beta[2] / (prior_sd^2)))
}

F_fn <- function(sigma, X, prior_sd) {
    crossprod(X) / (sigma^2) + diag(c(0, (1 / (prior_sd^2))))
}

# now put pieces together in an IWLS algorithm
iwls <- function(y, x, nsamples, sigma, beta_start, prior_mean, prior_sd) {
    # some setting for the algorithms and vectors/matrices to store results
    samples <- matrix(NA_real_, nrow = nsamples, ncol = length(beta_start))
    accepted <- vector(mode = "logical", length = nsamples)
    X <- cbind(1, x)
    
    # initialize with the starting values
    beta_current <- beta_start
    
    # since sigma^2 is treated as fixed, F can be computed beforehand
    Fval <- F_fn(sigma, X, prior_sd)
    Finv <- solve(Fval)
    Finv_chol <- t(chol(Finv))
    
    # perform MCMC iterations
    for (i in seq(nsamples)) {
        
        # IWLS proposal
        sval <- s_fn(y, X, beta_current, sigma, prior_sd)
        proposal_mean <- beta_current + drop(Finv  %*% sval)
        
        z <- rnorm(n = length(beta_start))
        beta_proposed <- drop(Finv_chol %*% z) + proposal_mean
        
        # acceptance step
        step <- mh_step_iwls(
            beta_proposed,
            beta_current,
            y,
            x,
            sigma,
            prior_mean,
            prior_sd,
            Finv
        )
        
        # update current state and store results
        beta_current <- step$beta
        samples[i,] <- beta_current
        accepted[i] <- step$accepted
    }
    
    # return the MCMC chain and the acceptance states
    return(list(beta = samples, accepted = accepted))
}

# set seed to make results reproducible
set.seed(123)

# call the sampler
samples <- iwls(
    dat$y,
    dat$x,
    nsamples = 10000,
    sigma = sqrt(3), # this is a parameter of the response distribution; we assume it to be fixed here
    beta_start = c(0, 0),
    prior_mean = 0,
    prior_sd = 10
)

# acceptance probability
mean(samples$accepted)

# view traceplots
matplot(samples$beta, type = "l")

# auto correlations
beta <- samples$beta
acf(beta[,1])
acf(beta[,2])

# estimates
colMeans(samples$beta)
apply(samples$beta, 2, sd)

# compare to lm results:
plot(dat$x, dat$y, xlab="x", ylab="y")
abline(lm(y~x, data=dat))
abline(coef=colMeans(samples$beta), col=2, lty=2)


beta <- samples$beta[-c(1:500),]
matplot(beta, type = "l")

# auto correlations
acf(beta[,1])
acf(beta[,2])

# estimates
colMeans(beta)
apply(beta, 2, sd)
