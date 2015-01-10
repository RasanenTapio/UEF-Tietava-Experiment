/* ############
This program can be used to transform inhomogeneous timeseries to homogeneous if SAS/IML is not available.
Program calculates intervals between ticks in data step processing and present them as tick frequency in output file. 
  
Take a tick data (inhomogeneous time series) of some symbol  and transform it to time series.
Copy csv-file to your SAS University Edition or SAS Studio folder.
Check File Format -document for correct informats.

Folders for importing tick data and one-minute data:
	/folders/myfolders/StockData/Trades
	/folders/myfolders/StockData/OMED
############ */

/* #### SETTINGS ##### */
libname STOCK "/folders/myfolders/StockData";

/* Select name and date */
%LET import_name = 14081; /* Available: 14081, 23444, 23870, 27667, 28082 */
%LET import_date = '4mar2014'd;

/* Select starting inverval from minutedata to match */
%lET time_interval = 1;
%LET time_unit = minute;
%LET start_time = '9:30:00't;

/* Suffix for outputfiles */
%LET output_suff = _&time_interval.&time_unit;
%LET imported_name = &import_name.&output_suff;

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

/* Import one-minute data */

data STOCK.MinuteData&import_name;
    format Date DDMMYYP10. Time Time12.;
    infile "/folders/myfolders/StockData/OMED/&import_name..csv" dlm=',' FIRSTOBS=2 
        TRUNCOVER;
    input Date :MMDDYY10. Time :hhmmss12. Open :14.7 High :14.7 Low :14.7 
        Close :14.7 Volume :8.;
     label Date = 'Date'
		Time = 'Time'
		Open = 'Open price'
		High = 'High price'
		Low = 'Low price'
		Close = 'Close price'
		Volume  = 'Volume';
run;

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

/* Import tick data */
data STOCK.TickData&import_name;
    format Date DDMMYYP10. Time Time12.;
    infile "/folders/myfolders/StockData/Trades/&import_name..csv" dlm=',';
    input Date :MMDDYY10. Time :hhmmss12. Price :14.7 Volume :9. 
        ExchangeCode :$2 SalesCondition :$4. CorrectionIndicator :$2. 
        SequenceNumber :9. TradeStopIndicator :$1. SourceOfTrade :$1.;
run;

/* Calculate tick frequency with number of ticks during inverval. */

data STOCK.stockdata&imported_name (keep = time_low time_up tickfreq volume_out open close high low
	rename=(time_low=time volume_out=volume));
	
	format time_low time12. time_up time12.;
	retain time_low time_up tickfreq volume_out open close high low;
	do i = 1 to _N_;
		set STOCK.TickData&import_name (where=(date=&import_date));
		if _N_ = 1 then do;
			/* interval starts at start_time: lower boundary */
			time_low = &start_time;
			/* interval ends at first_minute + 1minute: upper boundary */
			time_up= intnx("&time_unit", time_low, &time_interval);
			
			/* starting values for sums */
			tickfreq = 0;
			volume_out = 0;
			close = price;
			high = price;
			low = price;
			if time_low >= Time or time_up <= Time then Open = price;
			else if Open = 0;
		end;
		
		if time_low <= Time < time_up then do;
				tickfreq = tickfreq + 1;
				volume_out = volume_out + volume;
				close = price;
				if high < price then high = price;
				if low > price then low = price;
				if Open = 0 then Open = price;
		end;
		if time >= time_up then do;
			output;
			open = close;
			time_low = time_up;
			time_up = intnx("&time_unit", time_low, &time_interval);
			tickfreq= 0;
			volume_out = volume;
			high = price;
			low = price;
		end;
	end;
run;

/* Plot series to verify that everything was successful */

TITLE "Number of ticks per minute for stock &imported_name";
proc sgplot data = STOCK.stockdata&imported_name (obs=100);
    series x= time y = tickfreq / markers;
    series x= time y = volume /markers y2axis;
run;

proc sgplot data = STOCK.stockdata&imported_name (obs=100);
    series x= time y = open / markers;
    series x= time y = close/ markers;
    *series x= time y = volume_out/ markers y2axis;
run;

proc sgplot data = STOCK.stockdata&imported_name (obs=100);
    series x= time y = high/ markers;
    series x= time y = low / markers;
    *series x= time y = volume_out/ markers y2axis;
run;

/* Export csv-file for modelling and plotting */

proc export data = STOCK.stockdata&imported_name
   outfile="/folders/myfolders/StockData/stockdata&imported_name..csv"
   dbms=csv
   replace;
run;
