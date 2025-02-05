
# setwd("C:/arbeit/talks/Madrid2024/practicals")

library("bamlss")

# read the data
forest <- read.table("data/foresthealth.dat", header=TRUE)

# additive model with age and canopy density as covariates
b1 <- bamlss(def ~ s(age, bs="ps", m=c(3,2), k=10) + s(canopy, bs="ps", m=c(3,2), k=10),
             family="binomial", data=forest)
plot(b1)

# probit rather than logit model
b2 <- bamlss(def ~ s(age, bs="ps", m=c(3,2), k=10) + s(canopy, bs="ps", m=c(3,2), k=10),
             family=binomial_bamlss(link="probit"), data=forest)
plot(b2)

# add random effect per id
forest$id  <- as.factor(forest$id)
b3 <- bamlss(def ~ s(age, bs="ps", m=c(3,2), k=10) + s(canopy, bs="ps", m=c(3,2), k=10) +
            s(id, bs="re"), family="binomial", data=forest)
plot(b3)

# add a spatial effect based on coordinates
b4 <- bamlss(def ~ s(age, bs="ps", m=c(3,2), k=10) + s(canopy, bs="ps", m=c(3,2), k=10) +
               s(x,y), family="binomial", data=forest)
plot(b4)
