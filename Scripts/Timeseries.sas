/* Use one-minute trade data */
libname STOCK "/folders/myfolders/StockData";

/* Tick data and one-minute data:
/folders/myfolders/StockData/Trades
/folders/myfolders/StockData/OMED */
%LET import_name = 14081.csv;

/* One-Minute Data. Select informats according to description:

Date 		MM/DD/YYYY
Time		HH:MM:SS.mmm
Open		Number (14,7)
High		Number (14,7)
Low			Number (14,7)
Close		Number (14,7)
Volume		Integer (9)

03/03/2014,09:31,43.4,43.4,43.27,43.3,5587

Avoid using reserved SAS names!
*/

/* Import minute data for */
data STOCK.MinuteData;
    format Date DDMMYYP10. Time Time12.;
    infile "/folders/myfolders/StockData/OMED/&import_name" dlm=',' FIRSTOBS=2 
        TRUNCOVER;
    input Date :MMDDYY10. Time :hhmmss12. Open :14.7 High :14.7 Low :14.7 
        Close :14.7 Volume :8.;
     label Date = 'Date'
		Time = 'Time'
		Open_p = 'Open price'
		High_p = 'High price'
		Low_p = 'Low price'
		Close_p = 'Close price'
		Volume  = 'Volume';
run;

/* Import tick data for */
data STOCK.TickData14081;
    format Date DDMMYYP10. Time Time12.;
    infile "/folders/myfolders/StockData/Trades/&import_name" dlm=',';
    input Date :MMDDYY10. Time :hhmmss12. Price :14.7 Volume :9. 
        ExchangeCode :$2 SalesCondition :$4. CorrectionIndicator :$2. 
        SequenceNumber :9. TradeStopIndicator :$1. SourceOfTrade :$1.;
run;

/* Save plots (increased dpi ) */
ODS HTML image_dpi=300 GPATH='/folders/myfolders/Plots' 
    BODY='/folders/myfolders/Plots/plot.html';
TITLE 'Opening price for 3.3.2014';
FOOTNOTE 'One-minute data';

proc sgplot data=STOCK.MinuteData(where=(date='03mar2014'd));
	series x=time y=Open;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
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
run;

/* Calculate tick frequency with: number of ticks during inverval */

/* Select starting inverval from minutedata to match */
DATA _null_;
	SET STOCK.MinuteData (OBS = 10 where=(date='03mar2014'd));
	if _N_ = 1 then do;
		call symputx('first_minute', Time);
	end;
	stop;
RUN;

%lET time_interval = 10;
%PUT STARTING MINUTE: &first_minute INTERVAL: &time_interval MINUTES;

data test_tick (keep = time_min time_up tickfreq rename=time_min=time);
	format time_min time12. time_up time12.;
	retain time_min time_up tickfreq;
	do i = 1 to _N_;
		set STOCK.TickData14081 (where=(date='03mar2014'd));
		if _N_ = 1 then do;
			/* interval starts at first_minute: lower boundary */
			time_min = &first_minute;
			/* interval ends at first_minute + 1minute: upper boundary */
			time_up= intnx('minute', time_min, &time_interval);
			tickfreq = 0;
		end;
				
		if time_min <= Time < time_up then tickfreq = tickfreq + 1;
		if time >= time_up then do;
			output;
			time_min = time_up;
			time_up = intnx('minute', time_min, &time_interval);
			tickfreq= 0;	
		end;
	end;
run;

TITLE 'Number of ticks per minute for stock x';
proc sgplot data=test_tick (obs=100);
    series x= time y = tickfreq / markers;
run;

data test_minutedata;
	set STOCK.MinuteData (where=(date='03mar2014'd));
run;

/* proc sort data and merge by time */
proc sort data = test_tick; by time; run;
proc sort data = test_minutedata; by time; run; /* This time series time intervals should be same as test_tick's */

data test_comb;
	merge test_tick(in = aa) test_minutedata (in = bb);
	by time;
	if aa and bb;
	volume_n = - volume;
run;

/* Plot some series to test */

proc sgplot data=test_comb (obs=30);
	TITLE 'Number of ticks per minute for stock x';
	* highlow x=time high=high_p low=low_p / close = close_p;
	highlow x=time low = low high = high / lineattrs=(color=biyg thickness=10pt);
	series x=time y=close/ y2axis ;
	series x=time y=open;
run;

proc sgplot data = test_comb (obs=20);
   title "Number of ticks and closing price for stock x";
   vbar time / response = tickfreq;
   *vline time/ response = close; 
   vbar time / response = volume transparency=0.2 y2axis;
      refline 0 / axis = y;
      xaxis discreteorder = data;
run;

proc sgplot data=test_comb;
  band x = time upper = open lower =close / fill;
  needle x = time y = volume / y2axis;
  *yaxis min=0 grid;
  *y2axis display=(noticks novalues nolabel) offsetmax=0.7;
 run;

/* Export csv-file for modelling and plotting */
proc export data = test_comb
   outfile='/folders/myfolders/StockData/stockdata.csv'
   dbms=csv
   replace;
run;