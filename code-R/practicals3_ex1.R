
# setwd("C:/arbeit/talks/Madrid2024/practicals")

library("bamlss")
library("MASS")

# help page for the data set
?mcycle

# scatter plot
plot(mcycle$times, mcycle$accel, xlab="time in milliseconds", ylab="acceleration in g")

# mean regression model
b1 <- bamlss(accel ~ s(times, bs="ps", m=c(3,2), k=20), family="gaussian", data=mcycle)
plot(b1)
points(mcycle$times, mcycle$accel)

# location-scale model
mu <- accel ~ s(times, bs="ps", m=c(3,2), k=20)
sigma <- ~ s(times, bs="ps", m=c(3,2), k=20) 
b2 <- bamlss(list(mu, sigma), family="gaussian", data=mcycle)
plot(b2)

# model comparison
DIC(b1, b2)
WAIC(b1, b2)

