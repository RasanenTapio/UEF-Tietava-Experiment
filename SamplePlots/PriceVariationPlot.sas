/* 4.3.2014, symbol ITT */

%LET plotdata = STOCK.stockdata14081_5minute(where=('9:00:00't <= Time <= '16:00:00't));

proc sgplot data=&plotdata;
    TITLE "Number of ticks per minute";
    * highlow x=time high=high_p low=low_p / close = close_p;
    highlow x=time low=low high=high / lineattrs=(color=biyg thickness=7pt) 
        legendlabel='Price Variation';
    series x=time y=close /legendlabel='Closing Price' lineattrs=(color=red);
    needle x=time y=volume /y2axis lineattrs=(color=blue thickness=7pt) 
        legendlabel='Volume';
    yaxis min=43 grid;
    refline '11:49:00't / axis=x LABEL='Buy' LABELLOC=inside;
    refline '12:44:00't / axis=x LABEL='First alert' LABELLOC=inside;
    refline '13:58:00't / axis=x LABEL='Second alert' LABELLOC=inside;
    y2axis display=(noticks novalues nolabel) offsetmax=0.6;
run;

/* Some datapoints worth pointing out*/
data &plotdata;
	set &plotdata;
	if (tickfreq >= 180 and time <= '15:00:00't) or (tickfreq >= 400 and time > '15:00:00't) then tickfreq_lab = tickfreq;
	else tickfreq_lab = .;
	if (volume >= 30000 and time <= '15:00:00't) or (volume >= 50000 and time > '15:00:00't) then volume_lab = volume;
	else volume_lab = .;
	label time = 'Time';
run;

/* Plotting two plots top of each other */
proc template ;
    define statgraph stockprice;
        begingraph /  designwidth=10.5in designheight=5.5in;
        entrytitle "Stock Price, Volume and Tick Frequency of symbol ITT";
        entryfootnote "Price Variation and Closing Price, Volume and Tick Frequency, 5 minute intervals";
        layout lattice / columns=1 columndatarange=union rowweights=(0.7 0.3);
        	columnaxes;
        		columnaxis / offsetmin=0.02 griddisplay=on  ;
        	endcolumnaxes;
        	column2axes;
        		columnaxis /  label='Time';
        	endcolumn2axes;
        	layout overlay / yaxisopts=(LINEAROPTS=(VIEWMIN=43 VIEWMAX=44))
				xaxisopts=(label='Time') yaxisopts=(label='Price') y2axisopts=(offsetmax=0.6 label='Volume');
        		highlowplot x=time high=high low=low / lineattrs=(color=biyg thickness=5pt)
					legendlabel='Price Variation' name='vari';
        		seriesplot x=time y=close /legendlabel='Closing Price' lineattrs=(color=red)
					legendlabel='Closing Price' name = 'cprice';
        		needleplot x=time y=volume / yaxis=y2 lineattrs=(color=blue thickness=5pt)
					legendlabel='Volume' name='vol' datalabel=volume_lab;
        		discretelegend "vol" "cprice" "vari" / across=1 location=inside border=off halign=left valign=top  opaque=true;
        	endlayout;
        	layout overlay / yaxisopts=(label='Tick Frequency') xaxisopts=(label='Time');
        		needleplot x=time y=tickfreq /lineattrs=(color=FIREBRICK thickness=5pt)
					legendlabel='Tick Frequency' name='ticks' datalabel=tickfreq_lab;
        		discretelegend "ticks" / across=1 location=inside border=off halign=left valign=top  opaque=true;
        	endlayout;
        endlayout;
        endgraph;
    end;
run;

ods graphics on / width=10.5in height=5.5in;;

ODS HTML GPATH='/folders/myfolders/Plots' 
    BODY='/folders/myfolders/Plots/plot.png';

proc sgrender data=&plotdata template=stockprice;
run;

ODS HTML CLOSE;