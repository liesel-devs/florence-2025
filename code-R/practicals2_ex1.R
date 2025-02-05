
# setwd("C:/arbeit/talks/Madrid2024/practicals")

library("bamlss")

# read the data and the geographical information
zambia <- read.table("data/zambia.dat", header=TRUE)
zambia.bnd <- BayesX::read.bnd("data/zambia.bnd")
zambia.gra <- BayesX::read.gra("data/zambia.gra")

write.table(zambia.gra, "zambia_penalty.csv", sep=",", row.names=FALSE)

# visualise the districts and look at the neighborhood structure
plot(zambia.bnd)
head(zambia.gra)

# visualise the relation of the zscore to different covariates
plot(zambia$bmi, zambia$z, xlab="BMI of the mother", ylab="Z-score")
plot(zambia$age, zambia$z, xlab="age of the child in months", ylab="Z-score")
boxplot(zambia$z ~ zambia$survey, xlab="year of the survey", ylab="Z-score")

# create a dataset with average Z-score per district
plotdata <- by(zambia$z, zambia$district, mean)
plotdata <- data.frame(z=as.vector(plotdata), district=names(plotdata))
BayesX::drawmap(map=zambia.bnd, data=plotdata, plotvar="z",
                regionvar="district", swapcolors=TRUE)

# additive model with bmi and age as covariates
b1 <- bamlss(z ~ s(bmi, bs="ps", m=c(3,2), k=20) + s(age, bs="ps", m=c(3,2), k=20),
             family="gaussian", data=zambia)
#b1 <- bamlss(z ~ s(bmi, bs="ps", m=c(3,2), k=20) + s(age, bs="ps", m=c(3,2), k=20),
#             family="gaussian", data=zambia, n.iter = 12000, burnin = 0, thin = 10)
# visualise results and check MCMC samples
plot(b1)
plot(b1, which="samples")
plot(b1, which="max-acf")

# add a spatial effect
zambia$district <- factor(zambia$district, levels=names(zambia.bnd))
b2 <- bamlss(
  z ~ s(bmi, bs="ps", m=c(3,2), k=20) + s(age, bs="ps", m=c(3,2), k=20) +
             s(district, bs="mrf", xt=list(penalty=zambia.gra)),
  family="gaussian",
  data=zambia,
  drop.unused.levels=FALSE
)
plot(b2)

# random effect instead of spatial effect
b3 <- bamlss(z ~ s(bmi, bs="ps", m=c(3,2), k=20) + s(age, bs="ps", m=c(3,2), k=20) + s(district, bs="re"),
             family="gaussian", data=zambia)
plot(b3)

# compare spatial vs. random effect
p2 <- predict(b2, term=3,  model="mu")
p3 <- predict(b3, term=3,  model="mu")
p2 <- p2 - mean(p2)
p3 <- p3 - mean(p3)
plot(p2, p3)
abline(a=0, b=1)

# varying coefficients for age with respect to survey
zambia$survey1996 <- 1*(zambia$survey==1996)
zambia$survey2001 <- 1*(zambia$survey==2001)
b4 <- bamlss(z ~ s(bmi, bs="ps", m=c(3,2), k=20) + s(age, bs="ps", m=c(3,2), k=20) +
             s(age, bs="ps", m=c(3,2), k=20, by=survey1996) +
             s(age, bs="ps", m=c(3,2), k=20, by=survey2001)
             ,
             family="gaussian", data=zambia)
plot(b4)
plot(b4, term=4)


