# Bayesian Semiparametric Distributional Regression

Materials for the Workshop on Bayesian Semiparametric Distributional Regression in Florence, February 2025.

## Outline

This workshop provides an overview of key statistical modeling approaches, starting with the principles of Bayesian inference, followed by semiparametric regression with structured additive predictors, and concluding with distributional regression models. Topics include methods such as MCMC simulations, spline smoothing, and generalized additive models for location, scale, and shape, with a focus on both theory and application.

### Tuesday: Introduction to Bayesian Inference

- Principles of Bayesian Inference
- Markov Chain Monte Carlo Simulations
- Monitoring Mixing and Convergence
- Posterior Summaries

### Wednesday: Semiparametric Regression with Structured Additive Predictors

- Penalized Spline Smoothing
- A Generic Basis Function Framework
- Spatial Smoothing
- Random Effects Models
- Hyperpriors for the Smoothing Parameter
- Interactions and Identification

### Thursday: Distributional Regression Models

- Generalized Additive Models for Location, Scale and Shape
- Applications with Continuous, Discrete and Multivariate Responses
- Other Frameworks for Distributional Regression

## Prerequisites

- Please bring a **laptop**, so that you can actively work on the tutorials.
- On your laptop, you should have a recent version of R and RStudio installed.
- Prior programming experience:
  - You will need experience in R for the practicals of Day 1.
  - For the practicals of the Days 2 and 3, we offer two versions:
  - R version: Relies on the R package [`bamlss`](https://cran.r-project.org/web/packages/bamlss/vignettes/bamlss.html). This package is a great starting point for users familiar with R who want to apply Bayesian Semiparametric Distribtional Regression models.
  - Python version: Relies on the Python library [`liesel`](https://liesel-project.org). This library is our own development, and is our method of choice for developing new Bayesian models. Beware that the initial learning curve is higher than for `bamlss`, and that Liesel offers less convenience functionality out of the box. We will give you a brief introduction to Liesel on Day 2 of the workshop and provide solutions to all exercises for both options.
  - If you want to work on the Python exercises, we recommend to use [Google Colab](https://colab.research.google.com). Of course, you are free to use your own local Python installation, in which case we recommend the use of [Jupyter notebooks](https://jupyter.org). For details, see below.

## Schedule

### Tuesday, 11 February 2025: Fundamentals of Bayesian Inference

```
09:00 - 10:30 Lecture 1
10:30 - 11:00 Coffee Break
11:00 - 12:30 Lecture 2

12:30 - 14:00 Lunch Break

14:00 - 15:30 Practicals 1
15:30 - 16:00 Coffee Break
16:00 - 17:00 Practicals 2
```

### Wednesday, 12 February 2025: Semiparametric Regression with Structured Additive Predictors

```
09:00 - 10:30 Lecture 1
10:30 - 11:00 Coffee Break
11:00 - 12:30 Lecture 2

12:30 - 14:00 Lunch Break

14:00 - 15:30 Practicals 1
15:30 - 16:00 Coffee Break
16:00 - 17:00 Practicals 2
```

### Thursday, 13 February 2025: Distributional Regression Models

```
09:00 - 10:30 Lecture 1
10:30 - 11:00 Coffee Break
11:00 - 12:30 Lecture 2

12:30 - 14:00 Lunch Break

14:00 - 15:30 Practicals 1
15:30 - 16:00 Coffee Break
16:00 - 17:00 Practicals 2
```

## Getting started with Google Colab

To run Liesel on Google colab, you can simply upload the provided Jupyter notebooks
in `code-Python/` to [https://colab.research.google.com](https://colab.research.google.com).

## Using your own Python installation for Liesel

You can install the latest Liesel release via pip:

```
pip install liesel
```

We strongly recommend that you also install `pygraphviz`, as it is important for
plotting Liesel models. Installation for pygraphviz differs by operating system, please
refer to the documention: [PyGraphviz installation](https://pygraphviz.github.io/documentation/stable/install.html)

Tip: If you manage your Python installation through [conda](https://docs.conda.io/en/latest/), the
installation of PyGraphviz tends to work most easily.

For general-purpose plotting, we like to use [`plotnine`](https://plotnine.org), which brings ggplot2-like
syntax to Python:

```
pip install plotnine
```

To interface objects between R and Python, necessary functionality is provided in
the library [`rpy2`](https://rpy2.github.io):

```
pip install rpy2
```

## Support and Collaboration

- We are happy to support your work with Bayesian Distributional Regression! Please feel free to approach us with questions.
- You can contact the Liesel development team via `liesel@uni-goettingen.de`
- Please also feel encouraged to ask questions on our discussion board: <https://github.com/liesel-devs/liesel/discussions>
- Liesel documentation: <https://docs.liesel-project.org/en/latest/>


## Errata

### Practical Sheet 1

Errata in the R-solutions to exercises 3 and 4.

1. HMC
    1. We did not compute the sum for the joint log density of proposed and current momentum in acceptance probability.
    2. Used the wrong "current" momentum in the acceptance probability. We should use the newly drawn momentum in each iteration. We used the final momentum from the previous iteration.
2. IWLS
    1. We used the wrong means to evaluate the proposal densities in the acceptance probability. Specifically, we used the proposed and current parameter values, but we should have used the actual means for the forward and backward proposal distributions, which include the negative hessian and the gradient of the log posterior.
3. The negative hessian function `F_fn` contained errors.
    - Old: `crossprod(X) / (sigma) - (1 / (prior_sd^2))`
    - Corrected: `crossprod(X) / (sigma^2) + diag(c(0, (1 / (prior_sd^2))))`
    - Error one: Using `sigma` instead of `sigma^2`
    - Error two: Using `- (1 / prior_sd^2)` (subtraction) instead of `+ (1 / prior_sd^2)` (addition)
    - Error three: Treating `(1 / prior_sd^2)` as a scalar when it should be a 2x2 matrix with all zero-elements except for element [2,2], corresponding to beta[2].
4. The gradient of the log posterior `s_fn` contained errors.
    - Old: `(t(X) %*% y - crossprod(X) %*% beta) / (sigma^2) + (beta[1] / (prior_sd^2))`
    - Corrected: `(t(X) %*% y - crossprod(X) %*% beta) / (sigma^2) - c(0, (beta[2] / (prior_sd^2)))`
    - Error one: Using `beta[1]` instead of `beta[2]`
    - Error two: Adding the second term (wrong) instead of subtraction (correct)
    - Error three treating `beta[2] / (prior_sd^2)` as a scalar when it should be a 2x1 vector with the first element (corresponding to the intercept) being zero.
