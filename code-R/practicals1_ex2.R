
# setwd("C:/arbeit/talks/Madrid2024/practicals")

# read the data
dat <- read.table("data/linreg.dat", header=TRUE)

# plot and add the regression line from lm
plot(dat$x, dat$y, xlab="x", ylab="y")
abline(lm(y~x, data=dat))

# function for computing the log-posterior
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

# function for performing the acceptance step in an MH algorithm
mh_step <- function(beta_proposed, beta_current, y, x, sigma, prior_mean, prior_sd, rw_sd) {
  
  # log-posterior for the proposal and for the current value
  log_prob_proposal <- log_posterior(beta_proposed, y, x, sigma, prior_mean, prior_sd)
  log_prob_current <- log_posterior(beta_current, y, x, sigma, prior_mean, prior_sd)
  
  # log-density of the proposal distribution
  log_prob_backward <- sum(dnorm(beta_current, mean = beta_proposed, sd = rw_sd, log = TRUE))
  log_prob_forward <- sum(dnorm(beta_proposed, mean = beta_current, sd = rw_sd, log = TRUE))
  
  # log-acceptance probability
  log_alpha_star <- log_prob_proposal - log_prob_current + log_prob_backward - log_prob_forward
  log_acceptance_prob <- min(0, log_alpha_star)
  
  # determine acceptance by comparing to a log-uniform
  accept <- log(runif(n = 1)) < log_acceptance_prob
  
  # implement the acceptance step
  if(accept) {
    beta_step <- beta_proposed    
  } else {
    beta_step <- beta_current
  }
  
  # return the new state of the MCMC chain and whether acceptance took place
  return(list(beta = beta_step, accepted = accept))
}

# now put pieces together in an MH algorithm
mh_random_walk <- function(y, x, nsamples, sigma, beta_start, prior_mean, prior_sd, rw_sd) {
  
  # vector and matrix for storing the results
  samples <- matrix(NA_real_, nrow = nsamples, ncol = length(beta_start))
  accepted <- vector(mode = "logical", length = nsamples)
  
  # initialize with the starting values
  beta_current <- beta_start
  
  # perform MCMC iterations
  for (i in seq(nsamples)) {
    # random walk proposal
    beta_proposed <- rnorm(n = 2, mean = beta_current, sd = rw_sd)
    
    # MH step
    step <- mh_step(beta_proposed, beta_current, y, x, sigma, prior_mean, prior_sd, rw_sd)
    
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
samples <- mh_random_walk(
  dat$y,
  dat$x,
  nsamples = 100000,
  sigma = sqrt(3), # this is a parameter of the response distribution; we assume it to be fixed here
  beta_start = c(0, 0),
  prior_mean = 0,
  prior_sd = 10,
  rw_sd = 0.5
)

# acceptance probability
mean(samples$accepted)

# view traceplots
matplot(samples$beta, type = "l")
matplot(samples$beta[1:1000,], type = "l") # view burnin phase

# discard burnin
beta <- samples$beta[-c(1:1000),]
matplot(samples$beta, type = "l")

# auto correlations
acf(beta[,1])
acf(beta[,2])

# apply thinning to reduce autocorrelation
thinned_beta <- beta[seq(1, nrow(beta), by = 20),]
matplot(thinned_beta, type = "l")

# auto correlations
acf(thinned_beta[,1])
acf(thinned_beta[,2])

# estimates
colMeans(thinned_beta)
apply(thinned_beta, 2, sd)

# compare to lm results:
plot(dat$x, dat$y, xlab="x", ylab="y")
abline(lm(y~x, data=dat))
abline(coef=colMeans(thinned_beta), col=2, lty=2)




