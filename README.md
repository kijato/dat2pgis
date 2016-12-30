# Szerkesztés alatt...!


## dat2pgis, avagy a DAT adatcsere formátum kezelése PostgreSQL/PostGIS-ben

#### Előszó

Amióta elterjedt a hazai földmérésben a DAT adatcsere fomátum **(és mert sokáig állt rendelkezésemre semmilyen szoftver, amivel ezeket a "DAT-os" térképeket igazán hatékonyan kezelhettem)**, azon gondolkodtam, hogy hogyan tudnám a PostgreSQL adatbáziskezelő PostGIS nevű kiegészítőjével megoldani a különféle térinformatikai jellegű feladataimat, mint például a közigazgatási határok kezelése, különféle listák és poligonok szerinti földrészlet-leválogatások elvégzése, nagytömegben (egyszerre akár az egész megyét feldolgozva), lehetőleg minimális emberi beavatkozással. Mivel korábban már megoldottam az ITR ASCII állományok PostgreSQL/PostGIS-ben történő kezelését, nyilvánvaló volt, hogy ezt a feladatot a DAT adatcsere-formátummal is meg kellett tudni oldani...

#### Bevezetés

A leírás valójában nem egy konkrét programról szól, sokkal inkább egy módszerről, mellyel a DAT adatcsere formátumú fájlok a PostGIS segítségével feldogozhatók és ezt követően sokoldalúan felhasználhatók, hiszen ha már a térkép "be van töltve" az adatbázisba, akkor az érdemi adatokat a "nyers" SQL parancsoktól kezdve a QGis, Openjump szorftvereken át számtalan PostGIS kompatibilis programmal használhatjuk. *(Egy SHP export után például a DigiTerra Map-pal is.)*

Bár a "történet" a PostgreSQL és a PostGIS telepítésével kezdődik, előbb ejtsünk pár szót a DAT adatcsere formátumról, ami egy részletesen kidolgozott struktúra, mely egy viszonylag egyszerű felépítésű, szöveges adatfájlban ölt testet. Minden egyes fájl, a DAT szabályzatban rögzített táblázatoknak megfelelő szerkezetben tárolja az adatokat. A fejlécet követően egy-egy sor nevesíti a táblázatot, melyet a táblázat sorai követnek, az egyes adatokat '\*' karakterrel elválasztva.
Az DAT adatbázis kezelési egysége a település, mely a PostgreSQL adatbázisban egy-egy sémának nevezett gyűjtőben, a szabványon **alapuló**, előre létrehozott táblákba töltődik be. Így sémánként, azaz településenként ~80 tábla és ~20 tárolt eljárás keletkezik az adatbázisban, nyilvánvalóan némi replikációval... A választásom ezért esett mégis erre a megoldásra, mert így az egyes sémák, azaz települések önállóan is "életképesek": az adott séma egyszerűen exportálható, importálható, miközben az adatokkal, a tárolt eljárásokkal nem kell különösebben foglalkozni, sőt, még a sablont sem kell export-importálni. *(A tárolást meg lehet valósítani úgy is, hogy csak egyetlen sémát hozunk létre és annak a ~80 táblájába töltjük az adatokat, miközben a betöltést-törlést egy kiemelt táblában vezetjük.)*
A DAT szabvány elérhető itt: http://fish.fomi.hu/letoltes/nyilvanos/dat/DAT-M1_20160205.pdf

Ennyi kitérő után hozzunk létre egy PostgreSQL szervert!

#### PostgreSQL
Bár a PostgreSQL-nek létezik grafikus felületű, "automata" telepítője, én évek óta nem használom... Ehelyett az [EnterpriseDB](http://www.enterprisedb.com/products-services-training/pgbindownload) oldaláról letölthető ZIP-pel tömörített, hordozható változatot használom. Példaként a 9.4.8-as verziójú ZIP fájl-ból történő beüzemelést mutatom be, az alábbi batch fájlok alkalmazásával:

- datr_sablon_install.bat
- fmo-datr_sablon.sql
- pg_admin3.bat
- pg_conf.bat
- pg_init.bat
- pg_init_postgis.bat
- pg_start.bat
- pg_stop.bat

...

#### PostGIS
A PostGIS egy remek kiegészítő a PostgreSQL adatbázis kezelőhöz, mellyel térbeli adatokat tudunk adatbázisban kezelni, valahogy úgy, mint az Oracle Spatial-ban... (bővebb információt a technológiáról az Open Geospatial Consortium, Inc.® (OGC) honlapján találhatsz.)

A PostGIS-ben tárolt adatokat például olyan nyílt forrású programokkal kezelhetjük, mint az OpenJump, Quantum GIS, uDig, Grass, vagy mint a Mapserver, de akár egyszerű SQL utasításokkal is sokféle feladat megoldható, tulajdonképpen anélkül, hogy egyáltalán látnánk a térképet...

Az első PostGIS-sel tett próbálkozásaim óta azon voltam, hogy hogyan tudnám ezt a remek kiegészítőt egyes gyakran ismétlődő, unalmas, más programokkal sok egér-kattintást igénylő eljárások helyettesítésére használni... pár esetben ez már sikerült is, ezekről olvashatsz a következő oldalakon.
...
[postgis-bundle-pg94x32-2.1.8.zip](http://download.osgeo.org/postgis/windows/pg94/archive/postgis-bundle-pg94x32-2.1.8.zip)
[postgis-bundle-pg94x64-2.1.8.zip](http://download.osgeo.org/postgis/windows/pg94/archive/postgis-bundle-pg94x64-2.1.8.zip)
...

A táblázatok feltöltése adatokkal alapvetően nem túl bonyolult feladat: Egy

Egy igazi nehézség van, et leginkább az jelenti, hogy az adatcsere formátum "túl gyakran" változik, így vagy a betöltő-programot kell "felokosítani", vagy olyan egyszerűvé kell tenni, hogy bármikor módosítható legyen.

A betöltés maga tuljdonképpen egy nevetségesen egyszerű művelet, a DAT fájlból SQL utasításokat generálok, majd a betöltés után tárolt eljárásokkal (SQL és plpgsql) töltöm fel a geometria mezőket adatokkal.

#### Előfeltételek
A feldolgozás 
```
function test() {
  console.log("notice the blank line before this function?");
}
```
#### Perl

#######




Thanks to...
------------
[![PostgreSQL](https://wiki.postgresql.org/images/3/30/PostgreSQL_logo.3colors.120x120.png)](http://www.postgresql.org)
[![PostGIS](https://upload.wikimedia.org/wikipedia/en/6/60/PostGIS_logo.png)](http://www.postgis.org)
