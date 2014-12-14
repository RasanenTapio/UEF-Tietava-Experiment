/* Take a tick data (inhomogeneous time series) of some symbol  and transform it to time series.
   Calculate intervals between ticks and present them as tick frequency */
   
/* Copy csv-file to your SAS University Edition or SAS Studio folder.
Check File Format -document for correct informats. */
libname STOCK "/folders/myfolders/StockData";

/* Select informats according to description:

Date 					MM/DD/YYYY
Time					HH:MM:SS.mmm
Price					Number (14,7)
Volume					Integer (9)
Exchange Code			Character (2)
Sales Condition			Character (up to 4)
Correction Indicator	Character (up to 2)
Sequence				Number Integer (9)
Trade Stop Indicator	Character (1)
Source of Trade			Character (1)

*/
data STOCK.TickData;
    format Date DDMMYYP10. Time Time12.;
    infile '/folders/myfolders/StockData/tickdata.csv' dlm=',';
    input Date :MMDDYY10. Time :hhmmss12. Price :14.7 Volume :9. 
        ExchangeCode :$2 SalesCondition :$4. CorrectionIndicator :$2. 
        SequenceNumber :9. TradeStopIndicator :$1. SourceOfTrade :$1.;
run;

TITLE 'DESCRIPTIVE STATISTICS OF PRICE AND VOLUME';

proc means data=STOCK.TickData MAX MIN MEAN MEDIAN STD;
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