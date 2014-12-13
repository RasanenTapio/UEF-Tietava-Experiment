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
	input Date :MMDDYY10. Time :hhmmss12. Price :14.7 Volume :9. ExchangeCode :$2
		SalesCondition :$4. CorrectionIndicator :$2. SequenceNumber :9. TradeStopIndicator :$1.
		SourceOfTrade :$1.;
run;


TITLE 'DESCRIPTIVE STATISTICS OF PRICE AND VOLUME';
proc means data = STOCK.TickData N MAX MIN MEAN MEDIAN STD;
VAR Price Volume;
run;


/* First date is 3.3.2014, last is 5.3.2014 */
%LET date_i = %SYSFUNC(MDY(3, 3, 2014));

TITLE 'Price for 3.3.2014';
proc sgplot data = STOCK.TickData (where=(date = &date_i));
	series x=time y=Price / markers;
run;

/* 4.3.2014 */
%LET date_i = %SYSFUNC(MDY(3, 4, 2014));

TITLE 'Price for morning of 4.3.2014';
proc sgplot data = STOCK.TickData (where=(date = &date_i));
	series x=time y=Price / markers;
run;

/* Add an interval data to describe tick frequency.*/

/* Plot tick frequency and price before move. */

