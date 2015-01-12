/* Generate data with Timeseries.sas */
libname STOCK "/folders/myfolders/StockData";
ods graphics on / width=10.5in height=4.5in;

%LET plotdata = STOCK.stockdata14081_5minute(where=('9:00:00't <= Time <= '16:00:00't));
/* available 1, 5, 10, 15, 30 and 60 minute intervals:
	stockdata14081_1minute
	stockdata14081_5minute
	stockdata14081_10minute
	stockdata14081_15minute
	stockdata14081_30minute
	stockdata14081_60minute
with variables:
	time
	time_up
	tickfreq
	open
	close
	high
	low

*/

/* Plot some series to test */

proc sgplot data= &plotdata;
	TITLE "Number of ticks per minute";
	* highlow x=time high=high_p low=low_p / close = close_p;
	highlow x=time low = low high = high / lineattrs=(color=biyg thickness=7pt) legendlabel='Price Variation';
	series x=time y=close /legendlabel='Closing Price' lineattrs=(color=red);
	needle x=time y=volume /y2axis lineattrs=(color=blue thickness=7pt) legendlabel='Volume';;
	*bubble x=time y=volume size = tickfreq /  LEGENDLABEL='Tick frequency' y2axis datalabel = tickfreq NOOUTLINE;
	yaxis min=43 grid;
  	y2axis display=(noticks novalues nolabel) offsetmax=0.6;
	*xaxis interval = hour;
run;
/*
proc sgplot data=STOCK.customdata&imported_name;
  band x = time upper = open lower =close / fill;
  needle x = time y = volume / y2axis;
  yaxis min=40 grid;
  y2axis display=(noticks novalues nolabel) offsetmax=0.7;
 run;
 
TITLE "Number of ticks per minute for stock &imported_name";
proc sgplot data = STOCK.customdata&imported_name (obs=100);
    vbar time /response = tickfreq;
    vbar time /response = volume y2axis;
run;
*/


TITLE 'DESCRIPTIVE STATISTICS OF PRICE AND VOLUME';

proc means data=STOCK.TickData  MAX MIN MEAN MEDIAN STD;
	VAR Price Volume;
run;

/* First date is 3.3.2014, last is 5.3.2014 */
%LET date_3 = %SYSFUNC(MDY(3, 3, 2014));
TITLE 'Price for 3.3.2014';

proc sgplot data=STOCK.TickData (where=(date=&date_3));
    series x=time y=Price / markers;
run;

/* 4.3.2014 */
%LET date_4 = %SYSFUNC(MDY(3, 4, 2014));
TITLE 'Price for morning of 4.3.2014';

proc sgplot data=STOCK.TickData (where=(date=&date_4));
    series x=time y=Price / markers;
run;

/* Add an interval data to describe tick frequency.*/
data STOCK.IntervalData1 STOCK.IntervalData2 STOCK.IntervalData3;
    set STOCK.TickData (keep=Date Time Price Volume);

    if date=&date_3 then
        output STOCK.IntervalData1;
    else if date=&date_4 then
        output STOCK.IntervalData2;
    else
        output STOCK.IntervalData3;
run;

/* This data will be used to predict future price n moves ahead.
Required variables for model: tickfreq, some measurement of volume, price after/before/change? */
data testi;
    set STOCK.IntervalData1 (drop = date);
    tickfreq=dif(time);
    log_price = log(price);
    lag_log_price = lag(log_price);
    diff_price = dif(price);
    lag_diff_price = dif(log_price);
    log_volume=log(volume);
    lag_log_volume = lag(log_volume);
    
    /* For plotting bubbleplots:*/
	tickfreq_2 = 1/tickfreq;

    /* If this was divided by zero, then tick frequency is intensive */
	if tickfreq_2 = . then
        tickfreq_2=100;
      
run;

TITLE 'Tick frequency 3.3.2014, first 500 ticks';

proc sgplot data=testi (where=(tick_N <=500));
    series x=time y=tickfeq / markers;
    series x=time y=price / Y2AXIS;
run;

*ODS output doesn't work?!;
*ODS HTML BODY='/folders/myfolders/TickIntensity.html' style=HTMLBlue;
TITLE 'Tick frequency, Bubble plot';
TITLE2 'First 500 ticks, 3.3.2014';

proc sgplot data=testi (where=(tick_N <=500));
    bubble x=time y=price size=tickfreq_2 / LEGENDLABEL='Tick intensity' 
        NOOUTLINE;
    series x=time y=price / markers;
run;

TITLE2 'First 100 ticks, 4.3.2014';
proc sgplot data=testi (where=(tick_N <=100));
    bubble x=time y=price size=tickfreq_2 / LEGENDLABEL='Tick intensity' 
        NOOUTLINE;
    series x=time y=price / markers;
run;

*ODS HTML CLOSE;

TITLE2 'All observations, 3.3.2014';

proc sgplot data=testi (where=(tick_N <=30000));
    bubble x=time y=price size=tickfreq_2 / LEGENDLABEL='Tick intensity' 
        NOOUTLINE;
    series x=time y=price / Y2AXIS;
run;

* More options: BRADIUSMAX=10 Bradiusmin=0;
TITLE 'Trade volume distribution for trades under 2000 volume';

proc sgplot data=testi (where=(volume<=2000));
    histogram volume / BINSTART=0 BINWIDTH=100;
run;

/* Export csv-file for modelling */
proc export data = testi (drop = tickfreq_2)
   outfile='/folders/myfolders/StockData/intervaldata1.csv'
   dbms=csv
   replace;
run;


/* Save plots (increased dpi ) */
ODS HTML image_dpi=300 GPATH='/folders/myfolders/Plots' 
    BODY='/folders/myfolders/Plots/plot.png';
TITLE 'Opening price for 3.3.2014';
FOOTNOTE 'One-minute data';

proc sgplot data=STOCK.MinuteData(where=(date='03mar2014'd));
	series x=time y=Open;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
    where '09:30:00't <= time <= '16:00:00't;
    xaxis interval=hour MIN='09:30:00't;
run;

ODS HTML CLOSE;
TITLE 'Price for 4.3.2014';

proc sgplot data=STOCK.MinuteData(where=(date='04mar2014'd));
    series x=time y=Open;
    refline 43.95 / axis=y LABEL='Buy price';
run;

TITLE 'Price for 5.3.2014';

proc sgplot data=STOCK.MinuteData(where=(date='05mar2014'd));
    series x=time y=Open;
run;

TITLE 'High and Low Prices on 3.3.2014 between 12:00 and 15:30';
FOOTNOTE 'One-minute data, price variation';
proc sgplot data=STOCK.MinuteData(where=(date='03mar2014'd));
	BAND x = time UPPER = High LOWER = Low;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
    where '12:00:00't <= time <= '15:30:00't;
    xaxis interval=hour MAX='15:30:00't;
run;
