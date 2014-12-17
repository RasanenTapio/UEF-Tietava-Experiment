UEF-Tietava-Experiment
======================

Analytics experiment with R.

# Algorithm
Experiment on exit-strategy algorithm for intraday or high-frequency trade. Algorithm uses tick frequency, volume and price of single stock to predict future prices N steps ahead. If tick frequency is high, algorithm predicts N + X steps ahead, where X is some measurement of 1 divided by tick frequency.

If log return exceeds stop-loss limit, then algorithm will send out a signal to stop.

# Files
### Data
Historical Equities Data is available at https://www.tickdata.com/historical-market-data-products/historical-equities-data/
Both  tick data and time series data with one minute intervals are available.

### Scripts
**Intervals.sas** is used to generate evenly spaced time series from inhomogenous time series. File also includes code to generate some awesome plots.
**Timeseries.sas** is used to illustrate intraday trading decisions with plots.
**TestAlgorith.sas** is used to model algorithm. Tick data is used in algorithm testing.
### Sample Plots
Some sample plots created with scripts are included.
