
# setwd("C:/arbeit/talks/Madrid2024/practicals")

library("bamlss")

# read the data
rent <- read.table("data/rent.dat", header=TRUE)
rent_test <- read.table("data/rent_test.dat", header=TRUE)

rent$location <- as.factor(rent$location)
rent_test$location <- as.factor(rent_test$location)
rent$district <- as.factor(rent$district)
rent_test$district <- factor(rent_test$district)

# base regression model
b1 <- bamlss(rentsqm ~ s(area, bs="ps", m=c(3,2), k=20) +
             s(yearc, bs="ps", m=c(3,2), k=20) + location +
             s(district, bs="re"),
             family="gaussian", data=rent)


# DIC of the base model
DIC(b1)

# evaluate hold-out log-likelihood
p1 <- predict(b1, newdata=rent_test, type = "parameter")

ll <- sum(dnorm(rent_test$rentsqm, mean=p1$mu, sd=p1$sigma, log=TRUE))
ll
