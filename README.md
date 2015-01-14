UEF-Tietava-Experiment
======================

Predictive analytics experiment with trade data.

# Algorithm
Experiment on exit-strategy algorithm for intraday or high-frequency trade. Algorithm uses tick frequency, volume and price of single stock to predict future prices n steps ahead.

During every iteration of algorithm.
* One new observation is added to data
* Algorithm will select x models from all possible models.
* Selected models are weighted according to their prediction power
* Models are used to forecast n  steps ahead
* Finally, if log returns exceeds stop-loss limit, then algorithm will send out a signal to stop, else a new iteration with new data will begin.

# Files
### Data
Historical Equities Data is available at https://www.tickdata.com/historical-market-data-products/historical-equities-data/
Both  tick data and time series data with one minute intervals are available.

### Scripts and codes
**Timeseries.sas** is used to generate evenly spaced time series from inhomogenous time series. File also includes code to generate some awesome plots.
**TestAlgorith.r** is used to test algorithm. Data generated with Timeseries.sas from trade data is used in algorithm testing. Alert is reported and results are plotted as fanchart and exported as csv.
### Sample Plots
Some sample plots created with scripts and **PriceVariationPlot.sas** are included.
* Fanchart of forecast
* Price variation, volume and tick frequency of symbol, 5 minute intervals