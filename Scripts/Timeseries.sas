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

/* Save plots (increased dpi ) */
ODS HTML image_dpi=300 GPATH='/folders/myfolders/Plots' 
    BODY='/folders/myfolders/Plots/plot.html';
TITLE 'Opening price for 3.3.2014';
FOOTNOTE 'One-minute data';

proc sgplot data=STOCK.MinuteData(where=(date=%SYSFUNC(MDY(3, 3, 2014))));
	series x=time y=Open_p;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
run;

ODS HTML CLOSE;
TITLE 'Price for 4.3.2014';

proc sgplot data=STOCK.MinuteData(where=(date=%SYSFUNC(MDY(3, 4, 2014))));
    series x=time y=Open_p;
    refline 43.95 / axis=y LABEL='Buy price';
run;

TITLE 'Price for 5.3.2014';

proc sgplot data=STOCK.MinuteData(where=(date=%SYSFUNC(MDY(3, 5, 2014))));
    series x=time y=Open_p;
run;

TITLE 'High and Low Prices on 3.3.2014 between 12:00 and 15:30';
FOOTNOTE 'One-minute data, price variation';
proc sgplot data=STOCK.MinuteData(where=(date=%SYSFUNC(MDY(3, 3, 2014))));
	BAND x = time UPPER = High_p LOWER = Low_p;
    refline '12:11:30't / axis=x LABEL='12:11:30 buy' LABELLOC=inside;
    refline '15:00:00't / axis=x LABEL='15:00:00 sell' LABELLOC=inside;
    where '12:00:00't <= time <= '15:30:00't;
run;