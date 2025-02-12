
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

# function for computing the derivative of the log-posterior
log_posterior_deriv <- function(y, x, beta, sigma, prior_sd) {
    # contruct design matrix
    X <- cbind(1,x)
    
    # compute the derivative
    deriv <- (t(X) %*% y - crossprod(X) %*% beta) / (sigma^2) - c(0, (beta[2] / (prior_sd^2)))
    
    # return result
    return(deriv)
}

# HMC acceptance step
hmc_step <- function(beta_proposed, beta_current, momentum_proposed, momentum_current, y, x, sigma, prior_mean, prior_sd, mass_matrix) {
    # compute log-posterior at proposal
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
    
    # log-densities of the momentum
    # assumes that the mass matrix will always be diagonal
    log_prob_momentum_proposed <- dnorm(
        momentum_proposed,
        sd = sqrt(diag(mass_matrix)),
        log = TRUE
    ) |> sum()
    
    log_prob_momentum_current <- dnorm(
        momentum_current,
        sd = sqrt(diag(mass_matrix)),
        log = TRUE
    ) |> sum()
    
    # log-acceptance probability
    log_alpha_star <- (
        log_prob_proposal -
            log_prob_current +
            log_prob_momentum_proposed -
            log_prob_momentum_current
    )
    log_acceptance_prob <- min(0, log_alpha_star)
    
    # determine acceptance by comparing to a log-uniform
    accept <- log(runif(n = 1)) < log_acceptance_prob
    
    # implement the acceptance step
    if(accept) {
        beta_step <- beta_proposed
        # if accepted, negate the momentum
        # this is practically irrelevant, but part of the theory
        momentum_step <- -momentum_proposed 
    } else {
        beta_step <- beta_current
        momentum_step <- momentum_current
    }
    
    # return the new state of the MCMC chain and whether acceptance took place
    return(list(beta = beta_step, momentum = momentum_step, accepted = accept))
}

# now put pieces together in an HMC algorithm
hmc <- function(
        y,
        x,
        beta_start,
        sigma,
        prior_sd,
        nsamples,
        mass_matrix = diag(length(beta_start)),
        step_size = 0.1,
        number_steps = 10
) {
    
    # some setting for the algorithms and vectors/matrices to store results
    nparam <- length(beta_start)
    samples <- matrix(NA_real_, nrow = nsamples, ncol = nparam)
    accepted <- vector(mode = "logical", length = nsamples)
    Minv <- solve(mass_matrix)
    
    # initialize with the starting values
    beta_current <- beta_start
    
    
    # perform MCMC iterations
    for (m in seq(nsamples)) {
        
        # draw new momentum
        # assumes that the mass matrix will always be diagonal
        momentum_current <- rnorm(n = nparam, sd = sqrt(diag(mass_matrix)))
        
        # Leapfrog steps
        momentum_leapfrog <- momentum_current
        beta_leapfrog <- beta_current
        
        for (l in seq(number_steps)) {
            momentum_leapfrog <- momentum_leapfrog + (step_size / 2) * log_posterior_deriv(y, x, beta_leapfrog, sigma, prior_sd)
            beta_leapfrog <- beta_leapfrog + step_size * Minv %*% momentum_leapfrog
            
            if (l < number_steps) { # omit the last momentum update
                momentum_leapfrog <- momentum_leapfrog + (step_size / 2) * log_posterior_deriv(y, x, beta_leapfrog, sigma, prior_sd)
            }
        }
        
        # determine proposed values at the end of leapfrog steps
        beta_proposed <- beta_leapfrog
        momentum_proposed <- momentum_leapfrog
        
        # acceptance step
        step <- hmc_step(
            beta_proposed,
            beta_current,
            momentum_proposed,
            momentum_current,
            y,
            x,
            sigma,
            prior_mean = 0,
            prior_sd = prior_sd,
            mass_matrix = mass_matrix
        )
        
        # update current state and store results
        beta_current <- step$beta
        momentum_current <- step$momentum
        
        samples[m,] <- beta_current
        accepted[m] <- step$accepted
    }
    
    # return the MCMC chain and the acceptance states
    return(list(beta = samples, accepted = accepted))
}

# set seed to make results reproducible
set.seed(123)

# call the sampler
samples <- hmc(
    dat$y,
    dat$x,
    beta_start = c(0, 0),
    nsamples = 1000,
    sigma = sqrt(3), # this is a parameter of the response distribution; we assume it to be fixed here
    prior_sd = 10,
    step_size = 0.01,
    number_steps = 10
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


# --------------------------------------------------------------------------- #
# Comparison to package implementation in hmclearn
# --------------------------------------------------------------------------- #


logp <- function(beta) {
    log_posterior(
        beta,
        y=dat$y,
        x=dat$x,
        sigma=sqrt(3),
        prior_mean=0,
        prior_sd=10
    )
}

log_deriv <- function(beta) {
    log_posterior_deriv(y=dat$y, x=dat$x, beta=beta, sigma=sqrt(3), prior_sd=10)
}

res <- hmclearn::hmc(
    N=10000,
    theta.init = c(0,0),
    epsilon = 0.01,
    L = 10,
    logPOSTERIOR = logp,
    glogPOSTERIOR = log_deriv,
    randlength = FALSE,
    Mdiag = c(1,1),
    verbose = FALSE
)

res |> summary()

res$accept_v[[1]] |> mean()

res$thetaCombined[[1]][500:10000,] |> apply(2, sd)
