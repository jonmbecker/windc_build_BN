$TITLE Micro-consistency check without subnational trade flows :/

$IF NOT SET year $SET year 2016

* Set directory structure:
$IF NOT SET reldir $SET reldir "."

$IFTHENI %system.filesys% == UNIX $SET sep "/"
$ELSE $SET sep "\"
$ENDIF

PARAMETER ys0(r,s,g) "Sectoral supply";
PARAMETER id0(r,g,s) "Intermediate demand";
PARAMETER ld0(r,s) "Labor demand";
PARAMETER kd0(r,s) "Capital demand";
PARAMETER ty0(r,s) "Production tax";
PARAMETER m0(r,g) "Imports";
PARAMETER x0(r,g) "Exports of goods and services";
PARAMETER rx0(r,g) "Re-exports of goods and services";
PARAMETER md0(r,m,g) "Total margin demand";
PARAMETER nm0(r,g,m) "Margin demand from national market";
PARAMETER dm0(r,g,m) "Margin supply from local market";
PARAMETER s0(r,g) "Aggregate supply";
PARAMETER a0(r,g) "Armington supply";
PARAMETER ta0(r,g) "Tax net subsidy rate on intermediate demand";
PARAMETER tm0(r,g) "Import tariff";
PARAMETER cd0(r,g) "Final demand";
PARAMETER c0(r) "Aggregate final demand";
PARAMETER yh0(r,g) "Household production";
PARAMETER bopdef0(r) "Balance of payments";
PARAMETER hhadj(r) "Household adjustment";
PARAMETER g0(r,g) "Government demand";
PARAMETER i0(r,g) "Investment demand";
PARAMETER xn0(r,g) "Regional supply to national market";
PARAMETER xd0(r,g) "Regional supply to local market";
PARAMETER dd0(r,g) "Regional demand from local  market";
PARAMETER nd0(r,g) "Regional demand from national market";

ys0(r,s,g) = ys0_('%year%',r,s,g);
id0(r,g,s) = id0_('%year%',r,g,s);
ld0(r,s) = ld0_('%year%',r,s);
kd0(r,s) = kd0_('%year%',r,s);
ty0(r,s) = ty0_('%year%',r,s);
m0(r,g) = m0_('%year%',r,g);
x0(r,g) = x0_('%year%',r,g);
rx0(r,g) = rx0_('%year%',r,g);
md0(r,m,gm) = md0_('%year%',r,m,gm);
nm0(r,gm,m) = nm0_('%year%',r,gm,m);
dm0(r,gm,m) = dm0_('%year%',r,gm,m);
s0(r,g) = s0_('%year%',r,g);
a0(r,g) = a0_('%year%',r,g);
ta0(r,g) = ta0_('%year%',r,g);
tm0(r,g) = tm0_('%year%',r,g);
cd0(r,g) = cd0_('%year%',r,g);
c0(r) = c0_('%year%',r);
yh0(r,g) = yh0_('%year%',r,g);
bopdef0(r) = bopdef0_('%year%',r);
g0(r,g) = g0_('%year%',r,g);
i0(r,g) = i0_('%year%',r,g);
xn0(r,g) = xn0_('%year%',r,g);
xd0(r,g) = xd0_('%year%',r,g);
dd0(r,g) = dd0_('%year%',r,g);
nd0(r,g) = nd0_('%year%',r,g);
hhadj(r) = hhadj_('%year%',r);

PARAMETER y_(r,s) "Sectors and regions with positive production";
PARAMETER x_(r,g) "Disposition by region";
PARAMETER a_(r,g) "Absorption by region";

y_(r,s)$(sum(g, ys0(r,s,g))>0) = 1;
x_(r,g)$s0(r,g) = 1;
a_(r,g)$(a0(r,g) + rx0(r,g)) = 1;

$ONTEXT
$model:statemodel

$sectors:
	Y(r,s)$y_(r,s)		!	Production
	X(r,g)$x_(r,g)		!	Disposition
	A(r,g)$a_(r,g)		!	Absorption
	C(r)			!	Aggregate final demand
	MS(r,m)			!	Margin supply

$commodities:
	PA(r,g)$a0(r,g)		!	Regional market (input)
	PY(r,g)$s0(r,g)		!	Regional market (output)
	PD(r,g)$xd0(r,g)	!	Local market price
	PN(g)			!	National market
	PL(r)			!	Wage rate
	PK(r,s)$kd0(r,s)	!	Rental rate of capital
	PM(r,m)			!	Margin price
	PC(r)			!	Consumer price index
	PFX			!	Foreign exchange

$consumer:
	RA(r)			!	Representative agent

$prod:Y(r,s)$y_(r,s)  s:0 va:1
	o:PY(r,g)	q:ys0(r,s,g)            a:RA(r) t:ty0(r,s)    p:(1-ty0(r,s))    
	i:PA(r,g)	q:id0(r,g,s)
	i:PL(r)		q:ld0(r,s)	va:
	i:PK(r,s)	q:kd0(r,s)	va:

$prod:X(r,g)$x_(r,g)  t:4
	o:PFX		q:(x0(r,g)-rx0(r,g))
	o:PN(g)		q:xn0(r,g)
	o:PD(r,g)	q:xd0(r,g)
	i:PY(r,g)	q:s0(r,g)

$prod:A(r,g)$a_(r,g)  s:0 dm:2  d(dm):4
	o:PA(r,g)	q:a0(r,g)		a:RA(r)	t:ta0(r,g)	p:(1-ta0(r,g))
	o:PFX		q:rx0(r,g)
	i:PN(g)		q:nd0(r,g)	d:
	i:PD(r,g)	q:dd0(r,g)	d:
	i:PFX		q:m0(r,g)	dm: 	a:RA(r)	t:tm0(r,g) 	p:(1+tm0(r,g))
	i:PM(r,m)	q:md0(r,m,g)

$prod:MS(r,m)
	o:PM(r,m)	q:(sum(gm, md0(r,m,gm)))
	i:PN(gm)	q:nm0(r,gm,m)
	i:PD(r,gm)	q:dm0(r,gm,m)

$prod:C(r)  s:1
    	o:PC(r)		q:c0(r)
	i:PA(r,g)	q:cd0(r,g)

$demand:RA(r)
	d:PC(r)		q:c0(r)
	e:PY(r,g)	q:yh0(r,g)
	e:PFX		q:(bopdef0(r) + hhadj(r))
	e:PA(r,g)	q:(-g0(r,g) - i0(r,g))
	e:PL(r)		q:(sum(s,ld0(r,s)))
	e:PK(r,s)	q:kd0(r,s)

$OFFTEXT
$SYSINCLUDE mpsgeset statemodel

$IFTHENI %system.filesys% == MSNT
$CALL "copy statemodel.gen %reldir%%sep%temp%sep%statemodel.gen";
$CALL "del statemodel.gen";
$ENDIF


$IFTHENI %system.filesys% == UNIX
$CALL "cp statemodel.gen %reldir%%sep%temp%sep%statemodel.gen";
$CALL "rm statemodel.gen";
$ENDIF
