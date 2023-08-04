$title Build routine for the windc household dataset

*.$set start aggr
*.$set runscript hhcalib

*---- run after the core build is complete!! ---*

* to run individual build scripts, set %runscript% environment variable:
* $set runscript aggr

* ------------------------------------------------------------------------------
* Set options
* ------------------------------------------------------------------------------

* system separator
$set sep %system.dirsep%

* years of household cps data (options 2000-2021)
$set cps_years 2017

* years of tax return soi data (options 2014-2017)
$set soi_years 2017


*------------------------------------------------------------------------------
* Create directories if necessary
*------------------------------------------------------------------------------

$if not dexist datasets $call mkdir datasets
$if not dexist lst $call mkdir lst
$if not dexist gdx $call mkdir gdx
$set lstdir lst%sep%

parameter	myerrorlevel	Assigned to error level of the latest executation statement;

*------------------------------------------------------------------------------
* Data dimensions
*------------------------------------------------------------------------------

set
    year 		Years of data /%cps_years%/,
    soi_year(year) 	Years of soi data /%soi_years%/,
    hhdata 		Household data /cps,soi/,
    run(hhdata,year)	Years to run hhdata,
    invest 		Investment calibration options /static,dynamic/,
    rmap		Regional mappings /state/,
    smap		Sectoral mappings /windc,gtap_10,gtap_32/;

run('cps',year) = yes;
run('soi',soi_year) = yes;

*------------------------------------------------------------------------------
* Household build routine
*------------------------------------------------------------------------------

file kutl; kutl.lw=0; put kutl; kutl.nw=0; kutl.nd=0; kutl.pw=32767;

$if set runscript $goto %runscript%
$if set start     $goto %start%

* run cps_data.gms and soi_data.gms
loop(hhdata,
    put_utility 'title' /'Reading household dataset from ',hhdata.tl;
    put_utility 'exec'/'gams ',hhdata.tl,'_data o=%lstdir%',hhdata.tl,'_data.lst lo=4 lf=%lstdir%',hhdata.tl,'_data.log';
    myerrorlevel = errorlevel;
    if (myerrorlevel>1, abort "Non-zero return code from <hhdata>_data.gms"; );
);


* run hhcalib.gms for each year, cps/soi, and for static and dynamic investment:
$label hhcalib
loop((run(hhdata,year),invest),
    put_utility 'title' /'Calibrating ',year.tl,' with ',hhdata.tl,' with invest=',invest.tl;
    put_utility 'exec'/'gams hhcalib o=%lstdir%hhcalib_',year.tl,'_',hhdata.tl,'_',invest.tl,'.lst',
	' --year=',year.tl,' --hhdata=',hhdata.tl,' --invest=',invest.tl,' --puttitle=no',
	' lo=4 lf=%lstdir%hhcalib_',year.tl,'_',hhdata.tl,'_',invest.tl,'.log';
    myerrorlevel = errorlevel;
    if (myerrorlevel>1, abort "Non-zero return code from hhcalib.gms"; );

);

$if set runscript $exit

* impose steady-state investment demand on the model:

$label dynamic_calib
put_utility kutl, 'title' / 'Running dynamic_calib.gms';
loop(year,
    put_utility kutl, 'exec' /
	'gams dynamic_calib o=%lstdir%dynamic_calib_',year.tl,'.lst --year=',year.tl,
	' lo=4 lf=%lstdir%dynamic_calib_',year.tl,'.log';
    myerrorlevel = errorlevel;
    if (myerrorlevel>1, abort "Non-zero return code from dynamic_calib.gms"; );

);

$if set runscript $exit

* consolidate the datasets:
$label consolidate
loop(invest,

* cps data
    put_utility kutl, 'exec' /'gams consolidate o=%lstdir%consolidate_',"cps",'_',invest.tl,'.lst',
	' --hh_years=%cps_years% --hhdata=',"cps",' --invest=',invest.tl,
	' lo=4 lf=%lstdir%consolidate_',"cps",'_',invest.tl,'.log';
    display $sleep(1) "Waiting one second between consolidate job submissions.";
    myerrorlevel = errorlevel;
    if (myerrorlevel>1, abort "Non-zero return code from consolidate.gms"; );


* soi data
    put_utility kutl, 'exec' /'gams consolidate o=%lstdir%consolidate_',"soi",'_',invest.tl,'.lst',
	' --hh_years=%soi_years% --hhdata=',"soi",' --invest=',invest.tl,
	' lo=4 lf=%lstdir%consolidate_',"soi",'_',invest.tl,'.log';
    display $sleep(1) "Waiting one second between consolidate job submissions.";
    myerrorlevel = errorlevel;
    if (myerrorlevel>1, abort "Non-zero return code from consolidate.gms"; );
    
);
$if set runscript $exit


*------------------------------------------------------------------------------
* Aggregate the datasets
*------------------------------------------------------------------------------

$label aggr

set
    ds	Source datasets /cps_static,cps_dynamic,soi_static,soi_dynamic/,
    aggregate(ds,rmap,smap) Datasets to aggregate;

file kutl; kutl.lw=0; put kutl;

aggregate(ds,rmap,smap) = yes;

* these datasets are identical to the disaggregate dataset:

aggregate(ds,"state","windc") = no;

loop(aggregate(ds,rmap,smap),
    put_utility 'exec' / 'gams aggr --ds=',ds.tl,' --smap=',smap.tl,' --rmap=',rmap.tl,
	' o=%lstdir%aggr_',ds.tl,'_',smap.tl,'_',rmap.tl,'.lst',
	' lo=4 lf=%lstdir%aggr_',ds.tl,'_',smap.tl,'_',rmap.tl,'.log';
    myerrorlevel = errorlevel;
    if (myerrorlevel>1, abort "Non-zero return code from aggr.gms"; );

);

$if set runscript $exit


*------------------------------------------------------------------------------
* End
*------------------------------------------------------------------------------
