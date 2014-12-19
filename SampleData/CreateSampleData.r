# Code for creating sample data will be here

# install.packages("fGarch")

library(fGarch)

# From fGarch-package

# Create log prices from GARCH

## garchSpec -
# Use default parameters beside alpha:
spec = garchSpec(model = list(alpha = c(0.05, 0.05)))
spec
coef(spec)
## garchSim -
# Simulate an univariate "timeSeries" series
x = garchSim(spec, n = 200)
x = x[,1]
## garchFit -
fit = garchFit( ~ garch(1, 1), data = x)
## coef -
coef(fit)

plot(x) # looks too nice, needs a couple of local trends or level shifts

# create tick frequancy from

# create volume from

# test algorithm