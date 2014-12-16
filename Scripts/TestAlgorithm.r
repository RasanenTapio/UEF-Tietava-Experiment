# Use data created with Intervals.sas to predict price (with N = small)
# Use sample data if no real tick data is available
# Use previous day's data to train model

tickdata <- read.csv('C:/myfolders/StockData/intervaldata1.csv')

# Predict with model: log_price ~ lag_log_price + tickfeq + lag_log_volume
# Current price is explained by tick frequency, past prices and past volume

# parameters:
param_limit <- 0.05				# stop-loss limit
param_ci <- 0.95				# confidence intervals
param_buy <- 13.00				# buy price/current price
param_adjust_buy <- 0.005		# price adjustment for current price
param_n <- 10					# forecast n.ahead

dim(tickdata)
head(tickdata)

# Vector autoregression
library(vars)

# Loop over this data to simulate feed / Start of loop here
tickdata_c <- tickdata[1:100,c(4:5,8:9)]

# Remove days 1st transaction / tick
tickseries <- as.ts(tickdata_c[-1,-4])

# Try vector autoregression 

tickvar1 <- VAR(tickseries, p = 3, type = "none")
#VAR(tickseries, p = 2, type = "const")
#tickvar1 <- VAR(tickseries, p = 2, type = "trend")
#tickvar1 <- VAR(tickseries, p = 2, type = "both")

#plot(tickvar1)
AIC(tickvar1)

tickvar1p <- predict(tickvar1, n.ahead = param_n, ci = param_ci)
fanchart(tickvar1p)

# Residuals looking good...
plot(1:10, resid1, type='l')
abline(h=0)

# Forecasted values for price
dim(tickvar1p$fcst$log_price)
tickvar1p$fcst$log_price

# exp(log(price) = price
exp(tickvar1p$fcst$log_price[,1])
tickdata$Price[101:110]

resid1 <- tickdata$Price[101:110] - exp(tickvar1p$fcst$log_price[,1])

# Lower 5% limit
exp(tickvar1p$fcst$log_price[,1] - tickvar1p$fcst$log_price[,4])

# Returns with param_buy price
returns <- exp(tickvar1p$fcst$log_price[,1] - tickvar1p$fcst$log_price[,4]) - rep(param_buy,10)

min(returns) < -param_limit # FALSE: Does not exceed stop-loss limit, but:

plot(1:10, returns)

# predict log returns and risk n.ahead = param_n with ci = param_ci

# If result exceeds stop-loss limit then sell, else continue to monitor. / End of loop

# Print out results: Profit/Loss, Log price, parameters and compare forecast to real data