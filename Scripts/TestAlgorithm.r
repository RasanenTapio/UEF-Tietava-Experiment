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
tickdata$diff_tickfreq <- c(NA, diff(tickdata$log_tickfreq))
tickdata$diff_volume <- c(NA, diff(tickdata$log_volume))

# Validate after creating new variables
dim(tickdata)
head(tickdata)

# Price is explained by tick frequency, past price changes and past volume changes
# Predict with variables: diff_price, diff_volume and log_tickfreq

# Vector autoregression
library(vars)

# Parameters:
param_limit <- -0.005			# stop-loss limit
param_ci <- 0.95				# confidence intervals
param_buy_time <- 140			# time stock was bought (11:40:00)
param_n <- 15					# forecast n.ahead
max_alert = 0					# maximum alerts

# First alert
alert = 0
for(dd in 150:dim(tickdata)[1]){
	stop_signal = FALSE
	
	# Loop over this data to simulate feed / Start of loop here
	tickdata_c <- tickdata[(dd-100):dd, c("time","diff_price", "log_tickfreq", "diff_volume", "id")]

	# Remove days 1st transaction / tick
	tickseries <- as.ts(tickdata_c[,c("diff_price", "log_tickfreq", "diff_volume")])

	# Try vector autoregression
	allmodels <- as.data.frame(matrix(NA, nrow = 20, ncol = 3))
	names(allmodels) <- c("model", "AIC", "LL")
	bestmodels <- allmodels
	bestmodels$weight <- 1
	bestmodels$weight2 <- 1
	bestmodels$fcst <- 0
	names(bestmodels) <- c("model", "AIC", "LL", "weight", "weight2", "fcst")

	for(j in 1:20) {
		# Try vector autoregression

		if (j < 11) {
			try(test_model <- VAR(tickseries, p = j, type = "trend"))
			
			# Assign whole model to new variable
			assign(paste("model", j, sep=""),test_model)
			
			allmodels$model[j] <- paste("model", j, sep="")
			allmodels$AIC[j] <- AIC(test_model)
			allmodels$LL[j] <- logLik(test_model)[1]
		}
		if (j >= 11) {
			try(test_model <- VAR(tickseries, p = (j-10), type = "none"))
			
			# Assign whole model to new variable
			assign(paste("model", j, sep=""),test_model)
			
			allmodels$model[j] <- paste("model", j, sep="")
			allmodels$AIC[j] <- AIC(test_model)
			allmodels$LL[j] <- logLik(test_model)[1]
		}
	}

	# omit rows with NA
	allmodels <- na.omit((allmodels))

	# loop over and select x best
	x <- 3

	if (x > dim(allmodels)[1]){
		x <- dim(allmodels)[1]
	}

	for(k in 1:x) {
		try(bestmodels[k,1:3] <- subset(allmodels, AIC == min(allmodels$AIC, na.rm = TRUE)))
		allmodels <- subset(allmodels, AIC > min(allmodels$AIC, na.rm = TRUE))
	}
	bestmodels <- na.omit((bestmodels)); bestmodels
	allmodels

	# Calculate weights for best models
	bestmodels$weight <- bestmodels$AIC / (sum(bestmodels$AIC, na.rm = TRUE))
	bestmodels$weight2 <- bestmodels$LL / (sum(bestmodels$LL, na.rm = TRUE))

	bestmodels

	# Call variable with get and ger forecast for all best models
	for (m in 1:dim(bestmodels)[1]){
		tickforecast <- get(bestmodels$model[m])
		tickvar <- predict(tickforecast, n.ahead = param_n, ci = param_ci)
		bestmodels$fcst[m] <- sum(tickvar$fcst$diff_price[,1])
	}

	bestmodels

	# Subset by id >= buy time to get log returns
	log_returns_d <- subset(tickdata, id >= param_buy_time)
	# Sum historical and predicted log returns to get something to compare with stop-loss limit
	log_returns <- sum(log_returns_d$diff_price) + sum(bestmodels$weight * bestmodels$fcst)

	# If result exceeds stop-loss limit then send out signal, else continue to monitor. / End of loop
	log_returns  < log(1+param_limit) -> stop_signal

	if (stop_signal){
		if (alert == max_alert){
			dd_apu <- dd
			break
		}
		else {
			alert = alert + 1
		}
	}
}

subset(tickdata, id == param_buy_time)["time"]
subset(tickdata, id == dd_apu)["time"]

subset(tickdata, id == dd_apu)[["close"]] - subset(tickdata, id == param_buy_time)[["close"]]
exp(log_returns)
bestmodels

# Forecast with 3 best models and 
tickvar0 <- predict(model6, n.ahead = param_n, ci = param_ci) # create a forecast to be overwritten
tickvar1 <- predict(model16, n.ahead = param_n, ci = param_ci) # q = 6, without trend
tickvar2 <- predict(model13, n.ahead = param_n, ci = param_ci) # q = 3, without trend
tickvar3 <- predict(model6, n.ahead = param_n, ci = param_ci) # q = 6, with trend

wwei <- bestmodels$fcst

# Use calculated weights and combine
tickvar0$fcst$diff_price <- tickvar1$fcst$diff_price*wwei[1] + tickvar2$fcst$diff_price*wwei[2] + tickvar3$fcst$diff_price*wwei[3]
tickvar0$fcst$diff_volume <- tickvar1$fcst$diff_volume*wwei[1] + tickvar2$fcst$diff_volume*wwei[2] + tickvar3$fcst$diff_volume*wwei[3]
tickvar0$fcst$log_tickfreq <- tickvar1$fcst$log_tickfreq*wwei[1] + tickvar2$fcst$log_tickfreq*wwei[2] + tickvar3$fcst$log_tickfreq*wwei[3]
tickvar0

# And price and lower and upper limits
pricedata <- as.data.frame(exp(tickvar0$fcst$diff_price))
pricedata$closef1 <- 0
pricedata$closelower <-  0
pricedata$closeupper <-  0
pricedata$closeCI <-  0

pricedata$closef1[1] <- subset(tickdata, id == dd_apu-1)["close"]*pricedata$fcst[1]
pricedata$closelower[1] <- subset(tickdata, id == dd_apu-1)["close"]*pricedata$lower[1]
pricedata$closeupper[1] <- subset(tickdata, id == dd_apu-1)["close"]*pricedata$upper[1]
pricedata$closeCI[1] <- subset(tickdata, id == dd_apu-1)["close"]*pricedata$CI[1]

for(i in 2:dim(pricedata)[1]){
	pricedata$closef1[i] <- pricedata$closef1[[i-1]] * pricedata$fcst[i]

	pricedata$closelower[i] <- pricedata$closelower[[i-1]] * pricedata$lower[i]

	pricedata$closeupper[i] <- pricedata$closeupper[[i-1]] * pricedata$upper[i]

	pricedata$closeCI[i] <- pricedata$closeCI[[i-1]] * pricedata$CI[i]
}
pricedata <- as.data.frame(pricedata)


# Fanchart with some bright and cheerful colors
png(filename="C:/myfolders/StockData/fanchart.png", width = 1008, height = 828, pointsize = 18)

fanchart(tickvar0, colors=c("tomato", "orange"),
	main=c('Log Returns', 'Log Diff Volume','Log Tick Frequency'),
	xlab = 'Observation')
dev.off()

# Print out results: Profit/Loss, Log price, parameters and compare forecast to real data
write.table(bestmodels, file = 'C:/myfolders/StockData/results_bestmodels.csv')
write.table(tickvar0$fcst$diff_price, file = 'C:/myfolders/StockData/results_price.csv')
write.table(tickvar0$fcst$diff_volume, file = 'C:/myfolders/StockData/results_volume.csv')
write.table(tickvar0$fcst$log_tickfreq, file = 'C:/myfolders/StockData/results_tickfreq.csv')
#write.table(pricedata[,], file = 'C:/myfolders/StockData/results_pricedata.csv')
