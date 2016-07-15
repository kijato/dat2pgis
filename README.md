## dat2pgis, avagy a DAT adatcsere formátum kezelése PostgreSQL/PostGIS-ben

#### Előszó
Amióta elterjedt a hazai földmérésben a DAT adatcsere fomátum és **(nem állt rendelkezésemre semmilyen szoftver, amivel ezeket a térképeket igazán hatékonyan kezelhettem)**, azon gondolkodtam, hogy hogyan tudnám a PostgreSQL adatbáziskezelő PostGIS nevű kiegészítőjével megoldani a különféle térinformatikai jellegű feladataimat, mint például a közigazgatási határok kezelése, különféle listák, poligonok, szerinti földrészlet-leválogatások elvégzése, nagytömegben (egyszerre akár az egész megyét feldolgozva), lehetőleg minimális emberi beavatkozással.
Mivel korábban már megoldottam az ITR ASCII PostGIS-ben történő kezelését, nyilvánvaló volt, hogy ezt a feladatot a DAT adatcsere-formátummal is meg kellett tudni oldani...
E leírás valójában nem egy konkrét programról szól, sokkal inkább egy módszerről, mellyel a DAT adatcsere formátum feldogozható és sokoldalúan felhasználható.

#### Bevezetés
A DAT adatcsere formátum egy részletesen kidolgozott struktúra, mely egy viszonylag egyszerű felépítésű, szöveges adatfájlban ölt testet. Minden egyes fájl, a DAT szabvályzatban rögzített táblázatoknak megfelelő szerkezetben tárolja az adatokat. A fejlécet követően egy-egy sor nevesíti a táblázatot, melyet a táblázat sorai követnek, az egyes adatokat '*' karakterrel elválasztva.
A táblázatok adatbázisba szervezése, illetve az adatsorok betöltése alapvetően nem túl bonyolult feladat. A nehézséget az jelenti, hogy az adatcsere formátum "túl gyakran" változik, így vagy a betöltő-programot kell "felokosítani", vagy olyan egyszerűvé kell tenni, hogy bármikor módosítható legyen. Emiatt esett a választásom a Perl nyelvre...

Az adatbázis-kezelési egység a település, mely egy-egy sémának nevezett gyűjtőben létrehozott táblákba töltődik be...

A "program" a "csillagos DAT" fájl PostGIS-be történő betöltését végzi el, így a térképi állományok kezelhetők például a QGis, Openjump, illetve más szorftverekkel is, illetve egy SHP export után például DigiTerra-val is.

A betöltés maga tuljdonképpen egy nevetségesen egyszerű művelet, a DAT fájlból SQL utasításokat generálok, majd a betöltés után tárolt eljárásokkal (SQL és plpgsql) töltöm fel a geometria mezőket adatokkal.

A továbbiakban feltételezem, hogy ismered a PostgreSQL

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
