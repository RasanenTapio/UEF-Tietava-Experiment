/* 4.3.2014, symbol ITT */



%LET plotdata = STOCK.stockdata14081_5minute(where=('09:30:00't <= Aika<= '16:00:00't) rename=time=Aika);
%LET plotdata_1min = STOCK.stockdata14081_1minute(where=('11:00:00't <= Time <= '14:00:00't));

proc sgplot data=&plotdata_1min;
    TITLE "Hintamuutokset ja hälytykset";
    * highlow x=time high=high_p low=low_p / close = close_p;
    *highlow x=time low=low high=high / lineattrs=(color=biyg thickness=7pt) 
        legendlabel='Price Variation';
    series x=time y=close/legendlabel='Closing Price' lineattrs=(color=red);
    needle x=time y=volume /y2axis lineattrs=(color=blue thickness=7pt) 
        legendlabel='Volume';
    yaxis min=43 grid;
    refline '11:40:00't / axis=x LABEL='Ostohetki' LABELLOC=inside;
    refline '12:44:00't / axis=x LABEL='Ensimmäinen hälytys' LABELLOC=inside;
    refline '13:58:00't / axis=x LABEL='Toinen hälytys' LABELLOC=inside;
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
        entrytitle "Hinta, vaihtomäärä ja tapahtumien määräsymbolilla ITT";
        entryfootnote "Hinnan vaihtelu ja päätöshinta, vaihtomäärä ja tapahtumien määrä, 5 minuutin aikaväli";
        layout lattice / columns=1 columndatarange=union rowweights=(0.7 0.3);
        	columnaxes;
        		columnaxis / offsetmin=0.02 griddisplay=on  ;
        	endcolumnaxes;
        	column2axes;
        		columnaxis /  label='Aika';
        	endcolumn2axes;
        	layout overlay / yaxisopts=(LINEAROPTS=(VIEWMIN=43 VIEWMAX=44))
				xaxisopts=(label='Aika') yaxisopts=(label='Hinta, dollaria') y2axisopts=(offsetmax=0.6 label='Vaihtomäärä');
        		highlowplot x=Aika high=high low=low / lineattrs=(color=biyg thickness=5pt)
					legendlabel='Hinnan vaihtelu' name='vari';
        		seriesplot x=Aika y=close /legendlabel='Hinnan vaihtelu' lineattrs=(color=red)
					legendlabel='Päätöshinta' name = 'cprice';
        		needleplot x=Aika y=volume / yaxis=y2 lineattrs=(color=blue thickness=5pt)
					legendlabel='Vaihtomäärä' name='vol' datalabel=volume_lab;
        		discretelegend "vol" "cprice" "vari" / across=1 location=inside border=off halign=left valign=top  opaque=true;
        	endlayout;
        	layout overlay / yaxisopts=(label='Tapahtumien tiheys') xaxisopts=(label='Aika');
        		needleplot x=Aika y=tickfreq /lineattrs=(color=FIREBRICK thickness=5pt)
					legendlabel='Tapahtumien määrä' name='ticks' datalabel=tickfreq_lab;
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