UEF-Tietava-Experiment
======================

Analytics experiment with trade data.

# Algorithm
Experiment on exit-strategy algorithm for intraday or high-frequency trade. Algorithm uses tick frequency, volume and price of single stock to predict future prices N steps ahead. If tick frequency is high, algorithm predicts N + X steps ahead, where X is some measurement of 1 divided by tick frequency.

If log return exceeds stop-loss limit, then algorithm will send out a signal to stop.

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
