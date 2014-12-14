# Use data created with Intervals.sas to predict price (with N = small)
# Use sample data if no real tick data is available

tickdata <- read.csv('C:/myfolders/StockData/intervaldata1.csv')

# Predict with model: log_price ~ lag_log_price + tickfeq + lag_log_volume
# Current price is explained by tick frequency, past prices and past volume

dim(tickdata)
head(tickdata)

# Vector autoregression
library(vars)

tickdata_c <- tickdata[1:100,c(4:5,8:9)]

# Remove days 1st transaction / tick
tickseries <- as.ts(tickdata_c[-1,-4])

# Try vector autoregression 

tickvar1 <- VAR(tickseries, p = 2, type = "none")
#VAR(tickseries, p = 2, type = "const")
#tickvar1 <- VAR(tickseries, p = 2, type = "trend")
#tickvar1 <- VAR(tickseries, p = 2, type = "both")

plot(tickvar1)

tickvar1p <- predict(tickvar1, n.ahead = 10, ci = 0.95)
fanchart(tickvar1p)

# Forecasted values for price
dim(tickvar1p$fcst$log_price)
tickvar1p$fcst$log_price

# exp(log(price) = price
exp(tickvar1p$fcst$log_price[,1])
tickdata$Price[100:110]

resid1 <- tickdata$Price[101:110] - exp(tickvar1p$fcst$log_price[,1])

# Looking good...
plot(1:10, resid1, type='l')
abline(h=0)

# predict log returns and risk n.ahead = 10 with ci = 0.95

# Other methods:

# Try regression

# Try simple ARIMA (use one-minute or one-second tick data)

# Try GARCH