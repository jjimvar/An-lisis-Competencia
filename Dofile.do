log using "C:\Users\Usuario\OneDrive\Escritorio\3ro GANE\Mdo Trabajo\Informatica\Video Final\resultado.smcl", replace

cd "C:\Users\Usuario\OneDrive\Escritorio\3ro GANE\Mdo Trabajo\Informatica\Video Final"

*2. TRATAMIENTO DATOS:
**Importamos la base de datos y la unimos con otra que tiene menos variables (m:1)
use "datos-salarios.dta", replace
merge m:1 provempc1 year cnae09 using "hhi_prov.dta"
keep if _merge==3
describe

**Indicamos variables para estabcer base como datos de panel y seleccionamos submuestra balanceada:
xtset indiv year, yearly
xtdescribe
by indiv: gen Nano=[_N]
keep if Nano==9

**Analizamos variabilidad temporal (Within) y por individuo (Between)
global prueba edad edadempresa1 fijo
xtsum wage hhiprov $prueba 

**Análisis estadístico índice Herfindal:
***Distribución: Media y Mediana
sum hhiprov, detail
histogram hhiprov, saving("2dI.gph", replace) title("Concentración Empresarial") bin (10000) xline(365 1002) xlabel(0 365 1002 10000)
graph use 2dI.gph
graph export 2dI.png, replace

***Evolución por sector:
label define sac 1 "Agri" 2 "Ind" 3 "Cons" 4 "Com" 5 "Trans" 6 "Sfin" 7 "Spub" 8 "Otros"
label values sector_actividad sac

foreach value in 1 2 3 4 5 6 7 8 {
preserve
mean hhiprov wage if sector_actividad==`value'
restore
}

graph bar hhiprov , over(sector_actividad) saving("2dII.gph", replace) title("Concentración por Sectores")
graph bar wage , over(sector_actividad) saving("2dIII.gph", replace) title("Retribución por Sectores")
graph combine 2dII.gph 2dIII.gph, saving("2d.gph", replace)
graph use 2d.gph
graph export 2d.png, replace

*3. ESTIMACIÓN:
**Concretamos el salario:
gen lwage=log(wage)
global y lwage

**Concretamos el hhi:
gen lhhi=log(hhi)/100
global x0 lhhi

**Concretamos var indiv variantes t:
***Edad: 
gen ledad=log(edad)
***Antiguedad Contrato:
replace tenure=tenure/30
gen lcon=log(tenure)
***Definimos global:
global x1 ledad fijo lcon

**Concretamos var indiv invariantes t:
***Grupos de cotización:
gen grupcot=.
replace grupcot=3 if grtarifa==1 | grtarifa==2 | grtarifa==3| grtarifa==4
replace grupcot=2 if grtarifa==5 | grtarifa==8 | grtarifa==9
replace grupcot=1 if grtarifa==6 | grtarifa==7 | grtarifa==10 | grtarifa==11
label define gc 1 "Baja Calidad" 2 "Media Calidad" 3 "Alta Calidad"
label values grupcot gc

***Definimos global:
global x2 i.grupcot

**Concretamos var empresa variantes t:
***Edad empresa:
gen ledademp=log(edadempresa1)
***Tamaño de la empresa:
gen te=.
replace te=1 if tamemp>=1 | tamemp<=4
replace te=2 if tamemp==5 | tamemp==6
replace te=3 if tamemp==7 | tamemp==8
label define emp 1 "Pequeña" 2 "Mediana" 3 "Gran" 
label values te emp

***Definimos global:
global x3 ledademp i.te

**Concretamos var empresa invariantes t:
***Sector de actividad:
gen sa=.
replace sa=1 if sector_actividad==1
replace sa=2 if sector_actividad==2
replace sa=3 if sector_actividad==3
replace sa=4 if sector_actividad==4 | sector_actividad==5 | sector_actividad==6
replace sa=5 if sector_actividad==7 | sector_actividad==8

label define sact 1 "Agricultura" 2 "Industria" 3 "Construcción" 4 "Ss de mdo" 5 "Ss de no mdo"
label values sa sact

***Definimos global:
global x4 i.sa

**Concretamos años:
global x5 i.year

**Modelo Pooled:
reg $y $x0 $x1 $x2 $x3 $x4 $x5, vce(cluster indiv)
estimate store pooled0

**Modelo Random effects:
xtreg $y $x0 $x1 $x2 $x3 $x4 $x5, re
estimate store re0

**Modelo Fixed effects:
xtreg $y $x0 $x1 $x2 $x3 $x4 $x5, fe
estimate store fe0
test 2.sa=3.sa=4.sa=5.sa=0 //Significatividad SA

areg $y $x0 $x1 $x2 $x3 $x4 $x5, absorb(indiv)
estimate store lsdv0

**Resumen estimaciones:
estimate table pooled0 re0 fe0 lsdv0, stats (r2_a r2_o r2_w r2_b rho corr)

**Aclaración:
***Variable sexo y region de la empresa:
replace sexo=0 if sexo==2
label define genero 0 "Mujer"  1 "Hombre" 
label values sexo genero
***Comunidad:
gen autemp=.
replace autemp=1 if provempc1==4 | provempc1==11| provempc1==14 | provempc1==18 | provempc1==21 |provempc1==23 | provempc1==29 | provempc1==41
replace autemp=2 if provempc1==22 | provempc1==44| provempc1==50
replace autemp=3 if provempc1==33
replace autemp=4 if provempc1==7
replace autemp=5 if provempc1==35 | provempc1==38
replace autemp=6 if provempc1==39
replace autemp=7 if provempc1==5 | provempc1==9| provempc1==24 | provempc1==34 | provempc1==37 |provempc1== 40| provempc1==42 | provempc1==47| provempc1==49
replace autemp=8 if provempc1==2 | provempc1==13| provempc1==16 | provempc1==19 | provempc1==45
replace autemp=9 if provempc1==8 | provempc1==17| provempc1==25 | provempc1==43
replace autemp=10 if provempc1==3 | provempc1==12| provempc1==46
replace autemp=11 if provempc1==6 | provempc1==10
replace autemp=12 if provempc1==15 | provempc1==27| provempc1==32 | provempc1==36
replace autemp=13 if provempc1==28
replace autemp=14 if provempc1==30
replace autemp=15 if provempc1==31
replace autemp=16 if provempc1==1 | provempc1==48| provempc1==20
replace autemp=17 if provempc1==26
replace autemp=18 if provempc1==51
replace autemp=19 if provempc1==52
label define aut 1 "Andalucia" 2 "Aragón" 3 "Asturias" 4 "Baleares" 5 "Canarias" 6 "Cantabria" 7 "Castilla y León" 8 "Castilla-La Mancha" 9 "Cataluña" 10 "Comunidad Valenciana" 11 "Extremadura" 12 "Galicia" 13 "Comunidad de Madrid" 14 "Murcia" 15 "Navarra" 16 "País Vasco" 17 "La Rioja" 18 "Cueta" 19 "Melilla"
label values autemp aut
***Comunidad:
gen regemp=.
replace regemp=1 if autemp==1 | autemp==5 | autemp==11 | autemp==18 | autemp==19
replace regemp=2 if autemp==8 | autemp==10 | autemp==14 
replace regemp=3 if autemp==3 | autemp==6 | autemp==7 | autemp==12
replace regemp=4 if autemp==2 | autemp==4 | autemp==9 | autemp==17
replace regemp=5 if autemp==13 | autemp==15 | autemp==16 

label define ca 1 "Sur" 2 "Sureste" 3 "Noroeste" 4 "Noreste" 5 "Norte y Centro"
label values regemp ca

***Obsevamos multicolinealidad:
xtreg $y $x0 sexo inmigra i.regemp $x1 $x2 $x3 $x4 $x5, fe
tab grtarifa sexo
tab grtarifa inmigra
corr lhhi regemp

*4. HETEROCEDATICIDAD SECTOR
**Nuevo modelo:
xtreg $y $x1 $x2 $x3 $x4 $x5 c.lhhi#i.sa, re //para evitar multicolineadlidad
estimate store fe1

test 1.sa#lhhi=2.sa#lhhi=3.sa#lhhi=4.sa#lhhi=5.sa#lhhi

*5. HETEROCEDATICIDAD CONTRATO
**Nuevo modelo:
label define fij 0 "Discontinuo/Temporal" 1 "Fijo"
label values fijo fij
xtreg $y $x1 $x2 $x3 $x4 $x5 i.fijo#c.lhhi, re //para evitar multicolineadlidad
estimate store fe2

test 0.fijo#lhhi=1.fijo#lhhi=0

*6.HETEROCEDATICIDAD EDUCACIÓN
**Creamos global:
gen uni=0
replace uni=1 if niveleduca2>=5
label define un 0 "No universitario" 1 "Univesitario"
label values uni un

**Nuevo modelo:
xtreg $y $x1 uni $x3 $x4 $x5 i.uni#c.lhhi, re //para evitar multicolineadlidad
estimate store fe3

test 0.uni#lhhi=1.uni#lhhi

*7.HETEROCEDATICIDAD COTIZACION
**Nuevo modelo:
xtreg $y $x1 $x2 $x3 $x4 $x5 i.grupcot#c.lhhi, re //para evitar multicolineadlidad
estimate store fe4
 
test 1.grupcot#lhhi=2.grupcot#lhhi==3.grupcot#lhhi=0
 
log close



