# Use data created with Intervals.sas to predict price (with N = small)
# Use sample data if no real tick data is available
# Use previous day's data to train model

tickdata <- read.csv('C:/myfolders/StockData/stockdata14081_1minute.csv')

# Create new variables
tickdata$id <- 1:length(tickdata$time)
tickdata$log_price <- log(tickdata$close)
tickdata$diff_price <- c(NA, diff(tickdata$log_price))
# Add +1 to every value of tick freq
tickdata$tickfreq <- tickdata$tickfreq + 1
tickdata$log_tickfreq <- log(tickdata$tickfreq)
tickdata$log_volume <- log(tickdata$volume)
tickdata$diff_volume <- c(NA, diff(tickdata$log_volume))

# Validate after creating new variables
dim(tickdata)
head(tickdata)

# Price is explained by tick frequency, past price changes and past volume changes
# Predict with variables: diff_price, diff_volume and log_tickfreq

# Parameters:
param_limit <- -0.05			# stop-loss limit
param_ci <- 0.95				# confidence intervals
param_buy_time <- 3				# time stock was bought
param_adjust_buy <- 0.005		# price adjustment for current price
param_n <- 10					# forecast n.ahead

# Vector autoregression
library(vars)

# Loop over this data to simulate feed / Start of loop here
tickdata_c <- tickdata[3:100,c("time","diff_price", "log_tickfreq", "diff_volume", "id")]

# Remove days 1st transaction / tick
tickseries <- as.ts(tickdata_c[,c("diff_price", "log_tickfreq", "diff_volume")])

# Try vector autoregression

tickvar1 <- VAR(tickseries, p = 1, type = "both")
#VAR(tickseries, p = 2, type = "const")
#tickvar1 <- VAR(tickseries, p = 2, type = "trend")
#tickvar1 <- VAR(tickseries, p = 2, type = "both")

#plot(tickvar1)
AIC(tickvar1)

tickvar1p <- predict(tickvar1, n.ahead = param_n, ci = param_ci)
fanchart(tickvar1p)

# Forecasted values for price
tickvar1p$fcst$diff_price

# Subset by id >= buy time to get log returns
log_returns <- subset(tickdata_c, id >= param_buy_time)
# Sum historical and predicted log returns to get something to compare with stop-loss limit
log_returns <- sum(log_returns$diff_price) + sum(tickvar1p$fcst$diff_price[,1])

# If result exceeds stop-loss limit then send out signal, else continue to monitor. / End of loop
log_returns  < log(1+param_limit)

# Print out results: Profit/Loss, Log price, parameters and compare forecast to real data
