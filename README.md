## dat2pgis -> a DAT adatcsere formátum kezelése PostgreSQL/PostGIS-ben
Amióta egyeduralkodóvá vált az ingatlan-nyilvántartásban a DATR, illetve a hazai földmérésben *(legalábbis az ingatlan-nyilvántartást érintően)* a DAT adatcsere fomátum és  **nem állt rendelkezésemre semmilyen szoftver, amivel ezeket a térképeket kezelhetem**, azon mesterkedtem, hogy tudnám a PostGIS-be tölteni a "térképeimet" és abban megoldani a különféle térinformatikai jellegű feladataimat.
Mivel korábban más megoldottam az ITR ASCII PostGIS-ben történő kezelését...

A "program" a "csillagos DAT" fájl PostGIS-be történő betöltését végzi el, így a térképi állományok kezelhetők például a QGis, Openjump, illetve más szorftverekkel is: például egy SHP export után DigiTerra-val.

#### Bevezetés
A továbbiakban feltételezem, hogy ismered a 

#### Előfeltételek
A feldolgozás 

#### PostgreSQL
...

#### PostGIS
A PostGIS egy remek kiegészítő a PostgreSQL adatbázis kezelőhöz, mellyel térbeli adatokat tudunk adatbázisban kezelni, valahogy úgy, mint az Oracle Spatial-ban... (bővebb információt a technológiáról az Open Geospatial Consortium, Inc.® (OGC) honlapján találhatsz.)

A PostGIS-ben tárolt adatokat például olyan nyílt forrású programokkal kezelhetjük, mint az OpenJump, Quantum GIS, uDig, Grass, vagy mint a Mapserver, de akár egyszerű SQL utasításokkal is sokféle feladat megoldható, tulajdonképpen anélkül, hogy egyáltalán látnánk a térképet...

Az első PostGIS-sel tett próbálkozásaim óta azon voltam, hogy hogyan tudnám ezt a remek kiegészítőt egyes gyakran ismétlődő, unalmas, más programokkal sok egér-kattintást igénylő eljárások helyettesítésére használni... pár esetben ez már sikerült is, ezekről olvashatsz a következő oldalakon.
...

#### Perl

#######
DAT : http://fish.fomi.hu/letoltes/nyilvanos/dat/DAT-M1_20160205.pdf



Thanks to...
------------
[![PostgreSQL](https://wiki.postgresql.org/images/3/30/PostgreSQL_logo.3colors.120x120.png)](http://www.postgresql.org)
[![PostGIS](https://upload.wikimedia.org/wikipedia/en/6/60/PostGIS_logo.png)](http://www.postgis.org)
