* ------------------------------------------------------------------------------
*	 		  WiNDC Build Routine
*
* Authors: Andrew Schreiber, Thomas Rutherford, Adam Christensen
*
* ------------------------------------------------------------------------------

* NEOS Solvers: ALPHAECP, BARON, BDMLP, BONMIN, CBC, CONOPT, COUENNE, CPLEX, DICOPT,
*               GAMS-AMPL, IPOPT, KNITRO, LINDOGLOBAL, MILES, MINOS, MOSEK, NLPEC,
*               PATH, PATHNLP, SBB, SCIP, SNOPT, XPRESS

$IFTHENI %system.filesys% == UNIX $SET sep "/"
$ELSE $SET sep "\"
$ENDIF

$IF NOT SET reldir $SET reldir ".%sep%build_files"
$IF NOT SET dsdir $SET dsdir ".%sep%built_datasets"

$IF NOT SET neos $SET neos "no"
$IF NOT SET neosserver $SET neosserver "neos-server.org:3333"
$IF NOT SET kestrel_nlp $SET kestrel_nlp "conopt"
$IF NOT SET kestrel_lp $SET kestrel_lp "cplex"
$IF NOT SET kestrel_qcp $SET kestrel_qcp "cplex"
$IF NOT SET kestrel_mcp $SET kestrel_mcp "path"

$IF NOT SET aggr $SET aggr bluenote
$IF NOT SET year $SET year 2016

$onecho > cplex.opt
numericalemphasis 1
$offecho


SCALAR myerrorlevel;

*------------------------------------------------------------------------------
*** Check to make sure that core WiNDC database exists
*------------------------------------------------------------------------------
$IF NOT EXIST %dsdir%%sep%WiNDC_disagg_%aggr%.gdx $ERROR WiNDC_disagg_%aggr%.gdx database does not exist in %dsdir%, must first disaggregate with disagg.gms tool

$IF NOT EXIST %reldir%%sep%temp%sep%gdx_temp%sep%sectordisagg_%aggr%.gdx $ERROR Sector disaggregation sectordisagg_%aggr%.gdx does not exist in %reldir%%sep%temp%sep%gdx_temp%sep%, must first disaggregate with disagg.gms tool
*------------------------------------------------------------------------------


* ------------------------------------------------------------------------------
*** Re-calibration to Satellite Data
* ------------------------------------------------------------------------------

*** BLUENOTE ***
$IFTHENI.aggr "%aggr%" == "bluenote"
* The blueNOTE module seeks to pin down prices and quantities in the energy
* sectors of the : economic data which approximately match SEDS (along with CO2
* emissions). Note that additional data processing is required for SEDS and
* emissions totals. The routine outputs data for a SINGLE year, defined by
* %year%. We also use SEDS to separate the gas and oil extraction sector. A
* standard sectoral aggregation is defined within bluenote.gms. Customization
* requires individual treatment.

EXECUTE 'gams %reldir%%sep%readseds.gms o="%reldir%%sep%temp%sep%lst%sep%readseds.lst" --reldir=%reldir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: readseds.gms did not complete successfully...";

$IFTHENI "%neos%" == "yes"

EXECUTE 'gams %reldir%%sep%bluenote.gms --neos=yes solver=kestrel optfile=1 --kestrel_nlp=%kestrel_nlp% --kestrel_qcp=%kestrel_qcp% --year=%year% --matbal=ls o="%reldir%%sep%temp%sep%lst%sep%bluenote.lst" --aggr=%aggr% --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: bluenote.gms did not complete successfully...";

EXECUTE 'gams %reldir%%sep%enforcechk.gms --neos=yes solver=kestrel optfile=1 --kestrel_nlp=%kestrel_nlp% --kestrel_qcp=%kestrel_qcp% --year=%year% o="%reldir%%sep%temp%sep%lst%sep%enforcechk.lst" --aggr=%aggr% --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: enforcechk.gms did not complete successfully...";

$ELSE

EXECUTE 'gams %reldir%%sep%bluenote.gms nlp=ipopt qcp=cplex --year=%year% --matbal=ls o="%reldir%%sep%temp%sep%lst%sep%bluenote.lst" --aggr=%aggr% --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: bluenote.gms did not complete successfully...";

EXECUTE 'gams %reldir%%sep%enforcechk.gms nlp=ipopt qcp=cplex --year=%year% o="%reldir%%sep%temp%sep%lst%sep%enforcechk.lst" --aggr=%aggr% --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: enforcechk.gms did not complete successfully...";

$ENDIF

*** NASS ***
$ELSEIF.aggr "%aggr%" == "nass"

* EXAMPLE re-calibration to NASS aggregate sales totals by state and crop type.

$IFTHENI "%neos%" == "yes"

EXECUTE 'gams %reldir%%sep%nass.gms --neos=yes solver=kestrel optfile=1 --kestrel_nlp=%kestrel_nlp% --kestrel_qcp=%kestrel_qcp% --year=%year% --matbal=ls o="%reldir%%sep%temp%sep%lst%sep%nass.lst" --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: nass.gms did not complete successfully...";

EXECUTE 'gams %reldir%%sep%enforcechk.gms --neos=yes solver=kestrel optfile=1 --kestrel_mcp=%kestrel_mcp% --year=%year% o="%reldir%%sep%temp%sep%lst%sep%enforcechk.lst" --aggr=%aggr% --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: enforcechk.gms did not complete successfully...";

$ELSE

EXECUTE 'gams %reldir%%sep%nass.gms nlp=conopt qcp=cplex --year=%year% --matbal=ls o="%reldir%%sep%temp%sep%lst%sep%nass.lst" --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: nass.gms did not complete successfully...";


EXECUTE 'gams %reldir%%sep%enforcechk.gms nlp=conopt qcp=cplex --year=%year% o="%reldir%%sep%temp%sep%lst%sep%enforcechk.lst" --aggr=%aggr% --reldir=%reldir% --dsdir=%dsdir% > %system.nullfile%';
myerrorlevel = errorlevel;
ABORT$(myerrorlevel <> 0) "ERROR: enforcechk.gms did not complete successfully...";

$ENDIF

*** GTAP ***
* $ELSEIF.aggr "%aggr%" == "gtap"


$ENDIF.aggr
