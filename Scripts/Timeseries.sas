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
    input Date :MMDDYY10. Time :hhmmss12. Open_p :14.7 High_p :14.7 Low_p :14.7 
        Close_p :14.7 Volume :8.;
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
	series x=time y=Open_p;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
run;

ODS HTML CLOSE;
TITLE 'Price for 4.3.2014';

proc sgplot data=STOCK.MinuteData(where=(date='04mar2014'd));
    series x=time y=Open_p;
    refline 43.95 / axis=y LABEL='Buy price';
run;

TITLE 'Price for 5.3.2014';

proc sgplot data=STOCK.MinuteData(where=(date='05mar2014'd));
    series x=time y=Open_p;
run;

TITLE 'High and Low Prices on 3.3.2014 between 12:00 and 15:30';
FOOTNOTE 'One-minute data, price variation';
proc sgplot data=STOCK.MinuteData(where=(date='03mar2014'd));
	BAND x = time UPPER = High_p LOWER = Low_p;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
    where '12:00:00't <= time <= '15:30:00't;
run;

/* Calculate tick frequency with: number of ticks during inverval */

/* Select starting inverval from minutedata to match */
DATA _null_;
	SET STOCK.MinuteData (OBS = 10);
	if _N_ = 1 then do;
		call symputx('first_minute', Time);
	end;
	stop;
RUN;

%PUT STARTING MINUTE: &first_minute;

data test_tick (keep = low_min up_min count);
	format low_min time12. up_min time12.;
	retain low_min up_min count;
	do i = 1 to _N_;
		set STOCK.TickData14081 (where=(date='03mar2014'd));
		if _N_ = 1 then do;
			/* interval starts at first_minute: lower boundary */
			low_min = &first_minute;
			/* interval ends at first_minute + 1minute: upper boundary */
			up_min = intnx('minute',low_min,1);
			count = 0;
		end;
				
		if low_min <= Time < up_min then count = count + 1;
		if Time >= up_min then do;
			output;
			low_min = up_min;
			up_min = intnx('minute',Time,1);
			count = 0;	
		end;
	end;
run;

TITLE 'Number of ticks per minute for stock x';
proc sgplot data=test_tick (obs=100);
    series x=low_min y=count / markers;
run;

/* proc sort data and merge by time */



