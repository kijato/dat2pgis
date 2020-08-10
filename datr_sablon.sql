--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.15
-- Dumped by pg_dump version 9.6.17

-- Started on 2020-08-10 07:34:22

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 12 (class 2615 OID 26616704)
-- Name: datr_sablon; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA datr_sablon;


ALTER SCHEMA datr_sablon OWNER TO postgres;

--
-- TOC entry 51657 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA datr_sablon; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA datr_sablon IS 'DatR-ből kiírt DAT feldolgozása... (datr_sablon)';


--
-- TOC entry 14656 (class 1255 OID 26619171)
-- Name: alosztaly_megirasok_generalasa(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.alosztaly_megirasok_generalasa() RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  RETURN QUERY
  SELECT round(st_x(g.geometria)::numeric, 3) || ' ' ||
         round(st_y(g.geometria)::numeric, 3) || ' ' || 
         '0' || ' ' ||
         CASE bf.muvel_ag
            WHEN 1 THEN 'sz ' || bf.minoseg_oszt
            WHEN 2 THEN 'r ' || bf.minoseg_oszt
            WHEN 3 THEN 'sző ' || bf.minoseg_oszt
            WHEN 4 THEN 'k ' || bf.minoseg_oszt
            WHEN 5 THEN 'gy ' || bf.minoseg_oszt
            WHEN 6 THEN 'l ' || bf.minoseg_oszt
            WHEN 7 THEN 'n ' || bf.minoseg_oszt
            WHEN 8 THEN 'e ' || bf.minoseg_oszt
            WHEN 9 THEN 'mk'
            WHEN 10 THEN 'halastó ' || bf.minoseg_oszt
            WHEN 11 THEN 'fásítás ' || bf.minoseg_oszt
            ELSE 'HIBA!'
         END AS min_o_megiras
         /*CASE bf.muvel_ag
            WHEN 1 THEN 'szántó'
            WHEN 2 THEN 'gyep (rét)'
            WHEN 3 THEN 'szőlő'
            WHEN 4 THEN 'kert'
            WHEN 5 THEN 'gyümölcsös'
            WHEN 6 THEN 'gyep (legelő)'
            WHEN 7 THEN 'nádas'
            WHEN 8 THEN 'erdő'
            WHEN 9 THEN 'kivett'
            WHEN 10 THEN 'halastó'
            WHEN 11 THEN 'fásítás'
            ELSE 'HIBA!'
         END AS muvelesi_ag*/
  FROM datr_sablon.t_obj_attrbf bf
  LEFT JOIN ( SELECT t_obj_attrbf.felulet_id, st_pointonsurface(t_obj_attrbf.geometria) AS geometria
               FROM datr_sablon.t_obj_attrbf
             ) g ON bf.felulet_id = g.felulet_id;
EXCEPTION
  WHEN others THEN RETURN NEXT SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.alosztaly_megirasok_generalasa() OWNER TO postgres;

--
-- TOC entry 51658 (class 0 OID 0)
-- Dependencies: 14656
-- Name: FUNCTION alosztaly_megirasok_generalasa(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.alosztaly_megirasok_generalasa() IS 'Alosztály megírások beszúrási pontjának generálása';


--
-- TOC entry 14657 (class 1255 OID 26619172)
-- Name: bc_bd_letrehozas(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.bc_bd_letrehozas() RETURNS text
    LANGUAGE sql
    AS $$
CREATE OR REPLACE VIEW datr_sablon.bc_bd AS 
 SELECT bc.parcel_id id, bc.obj_fels, bc.felulet_id, bc.helyr_szam, bc.cim_id, bc.fekves, bc.kozter_jell, bc.terulet, bc.foldert, bc.forg_ertek, bc.val_nem, bc.szerv_tip, bc.jogi_jelleg, bc.jogallas, (-1) AS szemely_id, bc.ceg_id, bc.elhat_jell, bc.elhat_mod, bc.elozo_parcel_id elozo_id, bc.l_datum, bc.hatarozat, bc.valt_jell, bc.tar_hely, bc.blokk_id, bc.megsz_datum, bc.jelkulcs, bc.munkater_id, bc.pont_id, bc.geometria
   FROM datr_sablon.t_obj_attrbc bc
UNION 
 SELECT bd.parcel_id id, bd.obj_fels, bd.felulet_id, bd.helyr_szam, bd.cim_id, bd.fekves, (-1) AS kozter_jell, bd.terulet, bd.foldert, bd.forg_ertek, bd.val_nem, bd.szerv_tip, bd.jogi_jelleg, bd.jogallas, bd.szemely_id, bd.ceg_id, bd.elhat_jell, bd.elhat_mod, bd.elozo_parcel_id elozo_id, bd.l_datum, bd.hatarozat, bd.valt_jell, bd.tar_hely, bd.blokk_id, bd.megsz_datum, bd.jelkulcs, bd.munkater_id, bd.pont_id, bd.geometria
   FROM datr_sablon.t_obj_attrbd bd;
SELECT 'Kész!'::text;
$$;


ALTER FUNCTION datr_sablon.bc_bd_letrehozas() OWNER TO postgres;

--
-- TOC entry 51659 (class 0 OID 0)
-- Dependencies: 14657
-- Name: FUNCTION bc_bd_letrehozas(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.bc_bd_letrehozas() IS 'A BC és BD objektum-féleségeket egyetlen táblában összevonó funkció.';


--
-- TOC entry 14658 (class 1255 OID 26619173)
-- Name: find_el_id(numeric); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.find_el_id(hv_id numeric) RETURNS SETOF numeric
    LANGUAGE sql
    AS $_$
SELECT el_id
FROM datr_sablon.t_el
WHERE hatarvonal_id IN ($1)
$_$;


ALTER FUNCTION datr_sablon.find_el_id(hv_id numeric) OWNER TO postgres;

--
-- TOC entry 51660 (class 0 OID 0)
-- Dependencies: 14658
-- Name: FUNCTION find_el_id(hv_id numeric); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.find_el_id(hv_id numeric) IS '"Él" keresése "határvonal" azonosító alapján';


--
-- TOC entry 14659 (class 1255 OID 26619174)
-- Name: find_felulet_id(numeric); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.find_felulet_id(h_id numeric) RETURNS SETOF numeric
    LANGUAGE sql
    AS $_$
SELECT felulet_id
FROM datr_sablon.t_felulet
WHERE hatar_id IN ($1)
$_$;


ALTER FUNCTION datr_sablon.find_felulet_id(h_id numeric) OWNER TO postgres;

--
-- TOC entry 51661 (class 0 OID 0)
-- Dependencies: 14659
-- Name: FUNCTION find_felulet_id(h_id numeric); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.find_felulet_id(h_id numeric) IS '"Felület" keresése "határ" azonosító alapján';


--
-- TOC entry 14660 (class 1255 OID 26619175)
-- Name: find_gyuru_id(numeric); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.find_gyuru_id(h_id numeric) RETURNS SETOF numeric
    LANGUAGE sql
    AS $_$
SELECT gyuru_id
FROM datr_sablon.t_gyuru
WHERE hatar_id IN ($1)
$_$;


ALTER FUNCTION datr_sablon.find_gyuru_id(h_id numeric) OWNER TO postgres;

--
-- TOC entry 51662 (class 0 OID 0)
-- Dependencies: 14660
-- Name: FUNCTION find_gyuru_id(h_id numeric); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.find_gyuru_id(h_id numeric) IS '"Gyűrű" keresése "határ" azonosító alapján';


--
-- TOC entry 14661 (class 1255 OID 26619176)
-- Name: find_hatar_id(numeric); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.find_hatar_id(hv_id numeric) RETURNS SETOF numeric
    LANGUAGE sql
    AS $_$
SELECT hatar_id
FROM datr_sablon.t_hatar
WHERE hatarvonal_id IN ($1)
$_$;


ALTER FUNCTION datr_sablon.find_hatar_id(hv_id numeric) OWNER TO postgres;

--
-- TOC entry 51663 (class 0 OID 0)
-- Dependencies: 14661
-- Name: FUNCTION find_hatar_id(hv_id numeric); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.find_hatar_id(hv_id numeric) IS '"Határ" keresése "határvonal" azonosító alapján';


--
-- TOC entry 14662 (class 1255 OID 26619177)
-- Name: find_hatarvonal_id(numeric); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.find_hatarvonal_id(p_id numeric) RETURNS SETOF numeric
    LANGUAGE sql
    AS $_$
SELECT t_hatarvonal.hatarvonal_id
FROM datr_sablon.t_hatarvonal
WHERE pont_id_1 IN ($1)
   OR pont_id_2 IN ($1)
$_$;


ALTER FUNCTION datr_sablon.find_hatarvonal_id(p_id numeric) OWNER TO postgres;

--
-- TOC entry 51664 (class 0 OID 0)
-- Dependencies: 14662
-- Name: FUNCTION find_hatarvonal_id(p_id numeric); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.find_hatarvonal_id(p_id numeric) IS '"Határvonal" keresése "pont" azonosító alapján';


--
-- TOC entry 14663 (class 1255 OID 26619178)
-- Name: find_pont_id(numeric, numeric); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.find_pont_id(x numeric, y numeric) RETURNS SETOF numeric
    LANGUAGE sql
    AS $_$
SELECT pont_id
FROM datr_sablon.t_pont
WHERE round(pont_x,2)=round($1,2)
  AND round(pont_y,2)=round($2,2)
$_$;


ALTER FUNCTION datr_sablon.find_pont_id(x numeric, y numeric) OWNER TO postgres;

--
-- TOC entry 51665 (class 0 OID 0)
-- Dependencies: 14663
-- Name: FUNCTION find_pont_id(x numeric, y numeric); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.find_pont_id(x numeric, y numeric) IS '"Pont" keresése koordináta alapján';


--
-- TOC entry 14664 (class 1255 OID 26619179)
-- Name: geometria_mezo_feltoltes_ba(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_ba() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_ba(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_ba() OWNER TO postgres;

--
-- TOC entry 14665 (class 1255 OID 26619180)
-- Name: geometria_mezo_feltoltes_ba(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_ba(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrba');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrba;
  if generalt then
	  UPDATE datr_sablon.t_obj_attrba AS ba SET geometria=poligon_epites.geometria
	  FROM (
	    SELECT linestring_epites.felulet_id,
		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria
	    FROM (
	      SELECT f.felulet_id,
		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria
	      FROM datr_sablon.t_pont p1,
		   datr_sablon.t_pont p2,
		   datr_sablon.t_hatarvonal hv,
		   datr_sablon.t_hatar h,
		   datr_sablon.t_felulet f,
		   datr_sablon.t_obj_attrba aba
	      WHERE hv.pont_id_1=p1.pont_id
		AND hv.pont_id_2=p2.pont_id
		AND h.hatarvonal_id=hv.hatarvonal_id
		AND f.hatar_id=h.hatar_id
		AND f.felulet_id=aba.felulet_id
	      ) AS linestring_epites
	    GROUP BY felulet_id
	    ) AS poligon_epites
	  WHERE poligon_epites.felulet_id=ba.felulet_id;
  else
	  UPDATE datr_sablon.t_obj_attrba AS b SET geometria=f.geometria
	  FROM datr_sablon.t_felulet AS f
	  WHERE b.felulet_id=f.felulet_id;
  end if;
  --
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrba WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_ba(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51666 (class 0 OID 0)
-- Dependencies: 14665
-- Name: FUNCTION geometria_mezo_feltoltes_ba(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_ba(generalt boolean) IS 'A BA tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14666 (class 1255 OID 26619181)
-- Name: geometria_mezo_feltoltes_bb(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bb() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_bb(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bb() OWNER TO postgres;

--
-- TOC entry 14667 (class 1255 OID 26619182)
-- Name: geometria_mezo_feltoltes_bb(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bb(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrbb');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrbb;
  if generalt then
	 UPDATE datr_sablon.t_obj_attrbb AS bb SET geometria=poligon_epites.geometria
	  FROM (
	    SELECT linestring_epites.felulet_id,
		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria
	    FROM (
	      SELECT f.felulet_id,
		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria
	      FROM datr_sablon.t_pont p1,
		   datr_sablon.t_pont p2,
		   datr_sablon.t_hatarvonal hv,
		   datr_sablon.t_hatar h,
		   datr_sablon.t_felulet f,
		   datr_sablon.t_obj_attrbb abb
	      WHERE hv.pont_id_1=p1.pont_id
		AND hv.pont_id_2=p2.pont_id
		AND h.hatarvonal_id=hv.hatarvonal_id
		AND f.hatar_id=h.hatar_id
		AND f.felulet_id=abb.felulet_id
	      ) AS linestring_epites
	    GROUP BY felulet_id
	    ) AS poligon_epites
	  WHERE poligon_epites.felulet_id=bb.felulet_id;
  else
	  UPDATE datr_sablon.t_obj_attrbb AS b SET geometria=f.geometria
	  FROM datr_sablon.t_felulet AS f
	  WHERE b.felulet_id=f.felulet_id;
  end if;
  --
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrbb WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bb(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51667 (class 0 OID 0)
-- Dependencies: 14667
-- Name: FUNCTION geometria_mezo_feltoltes_bb(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bb(generalt boolean) IS 'A BB tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14668 (class 1255 OID 26619183)
-- Name: geometria_mezo_feltoltes_bc(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bc() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_bc(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bc() OWNER TO postgres;

--
-- TOC entry 14669 (class 1255 OID 26619184)
-- Name: geometria_mezo_feltoltes_bc(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bc(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrbc');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrbc;
  if generalt then
	  UPDATE datr_sablon.t_obj_attrbc AS bc SET geometria=poligon_epites.geometria
  FROM (
    SELECT linestring_epites.felulet_id,
           ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria
	    FROM (
	      SELECT f.felulet_id,
		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria
	      FROM datr_sablon.t_pont p1,
		   datr_sablon.t_pont p2,
		   datr_sablon.t_hatarvonal hv,
		   datr_sablon.t_hatar h,
		   datr_sablon.t_felulet f,
		   datr_sablon.t_obj_attrbc abc
	      WHERE hv.pont_id_1=p1.pont_id
		AND hv.pont_id_2=p2.pont_id
		AND h.hatarvonal_id=hv.hatarvonal_id
		AND f.hatar_id=h.hatar_id
		AND f.felulet_id=abc.felulet_id
	      ) AS linestring_epites
	    GROUP BY felulet_id
	    ) AS poligon_epites
	  WHERE poligon_epites.felulet_id=bc.felulet_id;
  else
	  UPDATE datr_sablon.t_obj_attrbc AS b SET geometria=f.geometria
	  FROM datr_sablon.t_felulet AS f
	  WHERE b.felulet_id=f.felulet_id;
  end if;
  --
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrbc WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bc(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51668 (class 0 OID 0)
-- Dependencies: 14669
-- Name: FUNCTION geometria_mezo_feltoltes_bc(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bc(generalt boolean) IS 'A BC tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14670 (class 1255 OID 26619185)
-- Name: geometria_mezo_feltoltes_bd(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bd() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_bd(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bd() OWNER TO postgres;

--
-- TOC entry 14671 (class 1255 OID 26619186)
-- Name: geometria_mezo_feltoltes_bd(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bd(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrbd');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrbd;
  if generalt then
	  UPDATE datr_sablon.t_obj_attrbd AS bd SET geometria=poligon_epites.geometria
	  FROM (
	    SELECT linestring_epites.felulet_id,
		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria
	    FROM (
	      SELECT f.felulet_id,
		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria
	      FROM datr_sablon.t_pont p1,
		   datr_sablon.t_pont p2,
		   datr_sablon.t_hatarvonal hv,
		   datr_sablon.t_hatar h,
		   datr_sablon.t_felulet f,
		   datr_sablon.t_obj_attrbd abd
	      WHERE hv.pont_id_1=p1.pont_id
		AND hv.pont_id_2=p2.pont_id
		AND h.hatarvonal_id=hv.hatarvonal_id
		AND f.hatar_id=h.hatar_id
		AND f.felulet_id=abd.felulet_id
	      ) AS linestring_epites
	    GROUP BY felulet_id
	    ) AS poligon_epites
	  WHERE poligon_epites.felulet_id=bd.felulet_id;
  else
	  UPDATE datr_sablon.t_obj_attrbd AS b SET geometria=f.geometria
	  FROM datr_sablon.t_felulet AS f
	  WHERE b.felulet_id=f.felulet_id;
  end if;
  --  
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrbd WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bd(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51669 (class 0 OID 0)
-- Dependencies: 14671
-- Name: FUNCTION geometria_mezo_feltoltes_bd(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bd(generalt boolean) IS 'A BD tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14672 (class 1255 OID 26619187)
-- Name: geometria_mezo_feltoltes_be(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_be() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_be(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_be() OWNER TO postgres;

--
-- TOC entry 51670 (class 0 OID 0)
-- Dependencies: 14672
-- Name: FUNCTION geometria_mezo_feltoltes_be(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_be() IS 'A BE tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14673 (class 1255 OID 26619188)
-- Name: geometria_mezo_feltoltes_be(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_be(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE  eredeti integer := 0;  szamlalo integer := 0;  uzenet text;  kezdes timestamp;  befejezes timestamp;BEGIN
  SELECT INTO kezdes clock_timestamp();  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrbe');  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrbe;  if generalt then
	  UPDATE datr_sablon.t_obj_attrbe AS be SET geometria=poligon_epites.geometria	  FROM (	    SELECT linestring_epites.felulet_id,		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria	    FROM (	      SELECT f.felulet_id,		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria	      FROM datr_sablon.t_pont p1,		   datr_sablon.t_pont p2,		   datr_sablon.t_hatarvonal hv,		   datr_sablon.t_hatar h,		   datr_sablon.t_felulet f,		   datr_sablon.t_obj_attrbe abe	      WHERE hv.pont_id_1=p1.pont_id		AND hv.pont_id_2=p2.pont_id		AND h.hatarvonal_id=hv.hatarvonal_id		AND f.hatar_id=h.hatar_id		AND f.felulet_id=abe.felulet_id	      ) AS linestring_epites	    GROUP BY felulet_id	    ) AS poligon_epites	  WHERE poligon_epites.felulet_id=be.felulet_id;  else	  UPDATE datr_sablon.t_obj_attrbe AS b SET geometria=f.geometria	  FROM datr_sablon.t_felulet AS f	  WHERE b.felulet_id=f.felulet_id;  end if;
  --  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrbe WHERE geometria IS NOT NULL;  SELECT INTO befejezes clock_timestamp();  RETURN uzenet || chr(10) ||         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;EXCEPTION   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_be(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51671 (class 0 OID 0)
-- Dependencies: 14673
-- Name: FUNCTION geometria_mezo_feltoltes_be(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_be(generalt boolean) IS 'A BE tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14674 (class 1255 OID 26619189)
-- Name: geometria_mezo_feltoltes_bf(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bf() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_bf(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bf() OWNER TO postgres;

--
-- TOC entry 51672 (class 0 OID 0)
-- Dependencies: 14674
-- Name: FUNCTION geometria_mezo_feltoltes_bf(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bf() IS 'A BF tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14675 (class 1255 OID 26619190)
-- Name: geometria_mezo_feltoltes_bf(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bf(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE  eredeti integer := 0;  szamlalo integer := 0;  uzenet text;  kezdes timestamp;  befejezes timestamp;BEGIN
  SELECT INTO kezdes clock_timestamp();  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrbf');  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrbf;  if generalt then
	  UPDATE datr_sablon.t_obj_attrbf AS bf SET geometria=poligon_epites.geometria	  FROM (	    SELECT linestring_epites.felulet_id,		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria	    FROM (	      SELECT f.felulet_id,		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria	      FROM datr_sablon.t_pont p1,		   datr_sablon.t_pont p2,		   datr_sablon.t_hatarvonal hv,		   datr_sablon.t_hatar h,		   datr_sablon.t_felulet f,		   datr_sablon.t_obj_attrbf abf	      WHERE hv.pont_id_1=p1.pont_id		AND hv.pont_id_2=p2.pont_id		AND h.hatarvonal_id=hv.hatarvonal_id		AND f.hatar_id=h.hatar_id		AND f.felulet_id=abf.felulet_id	      ) AS linestring_epites	    GROUP BY felulet_id	    ) AS poligon_epites	  WHERE poligon_epites.felulet_id=bf.felulet_id; else
	UPDATE datr_sablon.t_obj_attrbf AS b SET geometria=f.geometria	FROM datr_sablon.t_felulet AS f	WHERE b.felulet_id=f.felulet_id;  end if;
  --    SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrbf WHERE geometria IS NOT NULL;  SELECT INTO befejezes clock_timestamp();  RETURN uzenet || chr(10) ||         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;EXCEPTION   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bf(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51673 (class 0 OID 0)
-- Dependencies: 14675
-- Name: FUNCTION geometria_mezo_feltoltes_bf(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bf(generalt boolean) IS 'A BF tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14676 (class 1255 OID 26619191)
-- Name: geometria_mezo_feltoltes_bg(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bg() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_bg(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bg() OWNER TO postgres;

--
-- TOC entry 51674 (class 0 OID 0)
-- Dependencies: 14676
-- Name: FUNCTION geometria_mezo_feltoltes_bg(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bg() IS 'A bg tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14677 (class 1255 OID 26619192)
-- Name: geometria_mezo_feltoltes_bg(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_bg(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE  eredeti integer := 0;  szamlalo integer := 0;  uzenet text;  kezdes timestamp;  befejezes timestamp;BEGIN
  SELECT INTO kezdes clock_timestamp();  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrbg');  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrbg;  if generalt then	  UPDATE datr_sablon.t_obj_attrbg AS bg SET geometria=poligon_epites.geometria	  FROM (	    SELECT linestring_epites.felulet_id,		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria	    FROM (	      SELECT f.felulet_id,		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria	      FROM datr_sablon.t_pont p1,		   datr_sablon.t_pont p2,		   datr_sablon.t_hatarvonal hv,		   datr_sablon.t_hatar h,		   datr_sablon.t_felulet f,		   datr_sablon.t_obj_attrbg abg	      WHERE hv.pont_id_1=p1.pont_id		AND hv.pont_id_2=p2.pont_id		AND h.hatarvonal_id=hv.hatarvonal_id		AND f.hatar_id=h.hatar_id		AND f.felulet_id=abg.felulet_id	      ) AS linestring_epites	    GROUP BY felulet_id	    ) AS poligon_epites	  WHERE poligon_epites.felulet_id=bg.felulet_id;  else
	  UPDATE datr_sablon.t_obj_attrbg AS b SET geometria=f.geometria	  FROM datr_sablon.t_felulet AS f	  WHERE b.felulet_id=f.felulet_id;  end if;
  --    SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrbg WHERE geometria IS NOT NULL;  SELECT INTO befejezes clock_timestamp();  RETURN uzenet || chr(10) ||         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;EXCEPTION   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_bg(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51675 (class 0 OID 0)
-- Dependencies: 14677
-- Name: FUNCTION geometria_mezo_feltoltes_bg(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_bg(generalt boolean) IS 'A bg tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14678 (class 1255 OID 26619193)
-- Name: geometria_mezo_feltoltes_ca(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_ca() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  uzenet text;
BEGIN

  SELECT INTO uzenet datr_sablon.geometria_mezo_feltoltes_ca(true);
  RETURN uzenet;
  
EXCEPTION
   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_ca() OWNER TO postgres;

--
-- TOC entry 51676 (class 0 OID 0)
-- Dependencies: 14678
-- Name: FUNCTION geometria_mezo_feltoltes_ca(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_ca() IS 'A CA tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14679 (class 1255 OID 26619194)
-- Name: geometria_mezo_feltoltes_ca(boolean); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_ca(generalt boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE  eredeti integer := 0;  szamlalo integer := 0;  uzenet text;  kezdes timestamp;  befejezes timestamp;BEGIN
  SELECT INTO kezdes clock_timestamp();  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('obj_attrca');  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_obj_attrca;
  if generalt then	  UPDATE datr_sablon.t_obj_attrca AS ca SET geometria=poligon_epites.geometria	  FROM (	    SELECT linestring_epites.felulet_id,		   ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria	    FROM (	      SELECT f.felulet_id,		     ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria	      FROM datr_sablon.t_pont p1,		   datr_sablon.t_pont p2,		   datr_sablon.t_hatarvonal hv,		   datr_sablon.t_hatar h,		   datr_sablon.t_felulet f,		   datr_sablon.t_obj_attrca aca	      WHERE hv.pont_id_1=p1.pont_id		AND hv.pont_id_2=p2.pont_id		AND h.hatarvonal_id=hv.hatarvonal_id		AND f.hatar_id=h.hatar_id		AND f.felulet_id=aca.felulet_id	      ) AS linestring_epites	    GROUP BY felulet_id	    ) AS poligon_epites	  WHERE poligon_epites.felulet_id=ca.felulet_id;  else	  UPDATE datr_sablon.t_obj_attrca AS c SET geometria=f.geometria	  FROM datr_sablon.t_felulet AS f	  WHERE c.felulet_id=f.felulet_id;
  end if;  --    SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_obj_attrca WHERE geometria IS NOT NULL;  SELECT INTO befejezes clock_timestamp();  RETURN '[datr_sablon.t_obj_attrca]' || chr(10) ||         uzenet || chr(10) ||         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;EXCEPTION   WHEN others THEN RETURN SQLSTATE || ': ' || SQLERRM;END;$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_ca(generalt boolean) OWNER TO postgres;

--
-- TOC entry 51677 (class 0 OID 0)
-- Dependencies: 14679
-- Name: FUNCTION geometria_mezo_feltoltes_ca(generalt boolean); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_ca(generalt boolean) IS 'A CA tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14680 (class 1255 OID 26619195)
-- Name: geometria_mezo_feltoltes_felirat(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_felirat() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('felirat');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_felirat;
  UPDATE datr_sablon.t_felirat AS f
  SET geometria=ST_GeomFromText('POINT(' || p.pont_y || ' ' || p.pont_x || ')', 23700)
  FROM datr_sablon.t_pont p
  WHERE f.pont_id_text = p.pont_id;
  
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_felirat WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_felirat() OWNER TO postgres;

--
-- TOC entry 51678 (class 0 OID 0)
-- Dependencies: 14680
-- Name: FUNCTION geometria_mezo_feltoltes_felirat(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_felirat() IS 'A FELIRAT tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14681 (class 1255 OID 26619196)
-- Name: geometria_mezo_feltoltes_felulet(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_felulet() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('felulet');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_felulet;
  UPDATE datr_sablon.t_felulet AS f SET geometria=poligon_epites.geometria
  FROM (
    SELECT linestring_epites.felulet_id,
           ST_BuildArea(ST_Union(linestring_epites.geometria)) AS geometria
    FROM (
      SELECT f.felulet_id,
             ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700) AS geometria
      FROM datr_sablon.t_pont p1,
           datr_sablon.t_pont p2,
           datr_sablon.t_hatarvonal hv,
           datr_sablon.t_hatar h,
           datr_sablon.t_felulet f
      WHERE hv.pont_id_1=p1.pont_id
        AND hv.pont_id_2=p2.pont_id
        AND h.hatarvonal_id=hv.hatarvonal_id
        AND f.hatar_id=h.hatar_id
      ) AS linestring_epites
    GROUP BY felulet_id
    ) AS poligon_epites
  WHERE poligon_epites.felulet_id=f.felulet_id;
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_felulet WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_felulet() OWNER TO postgres;

--
-- TOC entry 51679 (class 0 OID 0)
-- Dependencies: 14681
-- Name: FUNCTION geometria_mezo_feltoltes_felulet(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_felulet() IS 'A FELULET tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14682 (class 1255 OID 26619197)
-- Name: geometria_mezo_feltoltes_hatar(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_hatar() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('hatar');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_hatar;
  UPDATE datr_sablon.t_hatar AS h
  SET geometria=ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700)
  FROM datr_sablon.t_pont p1,
       datr_sablon.t_pont p2,
       datr_sablon.t_hatarvonal hv
  WHERE hv.pont_id_1=p1.pont_id
    AND hv.pont_id_2=p2.pont_id
    AND h.hatarvonal_id=hv.hatarvonal_id;
  
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_hatar WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_hatar() OWNER TO postgres;

--
-- TOC entry 51680 (class 0 OID 0)
-- Dependencies: 14682
-- Name: FUNCTION geometria_mezo_feltoltes_hatar(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_hatar() IS 'A HATAR tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14683 (class 1255 OID 26619198)
-- Name: geometria_mezo_feltoltes_hatarvonal(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_hatarvonal() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('hatarvonal');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_hatarvonal;
  UPDATE datr_sablon.t_hatarvonal AS hv
  SET geometria=ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700)
  FROM datr_sablon.t_pont p1,
       datr_sablon.t_pont p2
  WHERE hv.pont_id_1=p1.pont_id
    AND hv.pont_id_2=p2.pont_id;
  
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_hatarvonal WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_hatarvonal() OWNER TO postgres;

--
-- TOC entry 51681 (class 0 OID 0)
-- Dependencies: 14683
-- Name: FUNCTION geometria_mezo_feltoltes_hatarvonal(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_hatarvonal() IS 'A HATARVONAL tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14684 (class 1255 OID 26619199)
-- Name: geometria_mezo_feltoltes_pont(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_pont() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('pont');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_pont;
  UPDATE datr_sablon.t_pont
  SET geometria=ST_GeomFromText('POINT(' || pont_y || ' ' || pont_x || ')', 23700);
  
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_pont WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_pont() OWNER TO postgres;

--
-- TOC entry 51682 (class 0 OID 0)
-- Dependencies: 14684
-- Name: FUNCTION geometria_mezo_feltoltes_pont(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_pont() IS 'A PONT tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14685 (class 1255 OID 26619200)
-- Name: geometria_mezo_feltoltes_vonal(); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_feltoltes_vonal() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  eredeti integer := 0;
  szamlalo integer := 0;
  uzenet text;
  kezdes timestamp;
  befejezes timestamp;
BEGIN
  SELECT INTO kezdes clock_timestamp();
  SELECT INTO uzenet datr_sablon.geometria_mezo_keszites('vonal');
  SELECT count (*) INTO STRICT eredeti FROM datr_sablon.t_vonal;
  UPDATE datr_sablon.t_vonal AS hv
  SET geometria=ST_GeomFromText( 'LINESTRING (' || p1.pont_y || ' ' || p1.pont_x || ', ' || p2.pont_y || ' ' || p2.pont_x || ')' , 23700)
  FROM datr_sablon.t_pont p1,
       datr_sablon.t_pont p2
  WHERE hv.pont_id_1=p1.pont_id
    AND hv.pont_id_2=p2.pont_id;
  
  SELECT count (*) INTO STRICT szamlalo FROM datr_sablon.t_vonal WHERE geometria IS NOT NULL;
  SELECT INTO befejezes clock_timestamp();
  RETURN uzenet || chr(10) ||
         'A ' || eredeti || ' darab geometriát tároló mezőt ' || szamlalo || ' esetben feltöltöttem!' || chr(10) ||
         'Kezdés:    ' || kezdes || chr(10) || 'Befejezés: ' || befejezes || chr(10) || 'Időtartam: ' || befejezes-kezdes;
EXCEPTION
   WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_feltoltes_vonal() OWNER TO postgres;

--
-- TOC entry 51683 (class 0 OID 0)
-- Dependencies: 14685
-- Name: FUNCTION geometria_mezo_feltoltes_vonal(); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_feltoltes_vonal() IS 'A vonal tábla geometriát tároló mezőjének feltöltése.';


--
-- TOC entry 14686 (class 1255 OID 26619201)
-- Name: geometria_mezo_keszites(character); Type: FUNCTION; Schema: datr_sablon; Owner: postgres
--

CREATE FUNCTION datr_sablon.geometria_mezo_keszites(tabla character) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  EXECUTE 'ALTER TABLE datr_sablon.t_' || tabla || ' ADD COLUMN geometria geometry;';
  EXECUTE 'CREATE INDEX i_' || tabla || '_geometria ON datr_sablon.t_' || tabla || ' USING gist (geometria);';
  RETURN 'A geometriát tároló mezőt a táblához [datr_sablon.t_' || tabla || '] hozzáadtam!';
EXCEPTION
  WHEN duplicate_column THEN /*
    EXECUTE 'ALTER TABLE datr_sablon.t_obj_attrba DROP COLUMN geometria';
    EXECUTE 'ALTER TABLE datr_sablon.t_obj_attrba ADD COLUMN geometria geometry;';
    EXECUTE 'CREATE INDEX i_t_obj_attrba_geometria ON datr_sablon.t_obj_attrba USING gist (geometria);';
    RETURN 'A geometriát tároló mező előzőleg már definiálva volt, ezért töröltem, majd újra létrehoztam!';*/
    EXECUTE 'UPDATE datr_sablon.t_' || tabla || ' SET geometria=NULL;';
    RETURN 'A geometriát tároló mezőt kiűrítettem!';
  WHEN others THEN RETURN SQLERRM;
END;
$$;


ALTER FUNCTION datr_sablon.geometria_mezo_keszites(tabla character) OWNER TO postgres;

--
-- TOC entry 51684 (class 0 OID 0)
-- Dependencies: 14686
-- Name: FUNCTION geometria_mezo_keszites(tabla character); Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON FUNCTION datr_sablon.geometria_mezo_keszites(tabla character) IS 'A paraméterként megadott tábla geometriát tároló mezőjének elkészítése. [Pl: "t_pont" helyett "pont" a megadandó]';


SET default_tablespace = '';

SET default_with_oids = true;

--
-- TOC entry 353 (class 1259 OID 26631319)
-- Name: t_obj_attrbc; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbc (
    parcel_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    helyr_szam character varying(15),
    cim_id numeric(10,0),
    fekves numeric(10,0),
    kozter_jell numeric(10,0),
    terulet numeric(12,3),
    foldert numeric(12,3),
    forg_ertek numeric(6,0),
    val_nem character varying(3),
    szerv_tip numeric(10,0),
    jogi_jelleg numeric(10,0),
    jogallas numeric(10,0),
    ceg_id numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_parcel_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    valt_jell character varying(20),
    tar_hely character varying(20),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0),
    geometria public.geometry
);


ALTER TABLE datr_sablon.t_obj_attrbc OWNER TO postgres;

--
-- TOC entry 51685 (class 0 OID 0)
-- Dependencies: 353
-- Name: TABLE t_obj_attrbc; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbc IS 'Földrészletek I. (közterületi)';


--
-- TOC entry 51686 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.parcel_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.parcel_id IS 'Földrészlet azonosító sorszáma a DAT-ban';


--
-- TOC entry 51687 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.obj_fels IS 'Földrészlet objektumféleségének kódja';


--
-- TOC entry 51688 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.felulet_id IS 'A földrészlet geometriáját leíró felület azonosítója';


--
-- TOC entry 51689 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.helyr_szam IS 'A földrészlet helyrajzi száma';


--
-- TOC entry 51690 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.cim_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.cim_id IS 'A földrészlet postacímének kódja';


--
-- TOC entry 51691 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.fekves; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.fekves IS 'Fekvés kódja';


--
-- TOC entry 51692 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.kozter_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.kozter_jell IS 'Közterület jelleg kódja';


--
-- TOC entry 51693 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.terulet IS 'Számított terület nagysága';


--
-- TOC entry 51694 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.foldert; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.foldert IS 'Földérték';


--
-- TOC entry 51695 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.forg_ertek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.forg_ertek IS 'A földrészlet szerzéskori forgalmi értéke';


--
-- TOC entry 51696 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.val_nem; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.val_nem IS 'A forgalmi érték valuta neme';


--
-- TOC entry 51697 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.szerv_tip; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.szerv_tip IS 'Szektor';


--
-- TOC entry 51698 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.jogi_jelleg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.jogi_jelleg IS 'Jogi jelleg';


--
-- TOC entry 51699 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.jogallas; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.jogallas IS 'Jogállás';


--
-- TOC entry 51700 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.ceg_id IS 'Vagyonkezelő vagy használó szervezet  név- és címadatai';


--
-- TOC entry 51701 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51702 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51703 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.elozo_parcel_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.elozo_parcel_id IS 'A földrészlet legutóbb érvényes adatrekordjának azonosítója';


--
-- TOC entry 51704 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.l_datum IS 'Dátum';


--
-- TOC entry 51705 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 51706 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.valt_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.valt_jell IS 'Változási jelleg (pl. egyesítés, szolgalmi jog)';


--
-- TOC entry 51707 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.tar_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.tar_hely IS 'Változási vázrajz tárolási helye';


--
-- TOC entry 51708 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.blokk_id IS 'A földrészletet és környezetét dokumentáló légi fénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51709 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51710 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51711 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51712 (class 0 OID 0)
-- Dependencies: 353
-- Name: COLUMN t_obj_attrbc.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbc.pont_id IS 'Földrészlet geokódját kijelölő pont azonosítója';


--
-- TOC entry 354 (class 1259 OID 26631325)
-- Name: t_obj_attrbd; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbd (
    parcel_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    helyr_szam character varying(15),
    cim_id numeric(10,0),
    fekves numeric(10,0),
    terulet numeric(12,3),
    foldert numeric(12,3),
    forg_ertek numeric(6,0),
    val_nem character varying(3),
    szerv_tip numeric(10,0),
    jogi_jelleg numeric(10,0),
    jogallas numeric(10,0),
    szemely_id numeric(10,0),
    ceg_id numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_parcel_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    valt_jell character varying(20),
    tar_hely character varying(20),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0),
    geometria public.geometry
);


ALTER TABLE datr_sablon.t_obj_attrbd OWNER TO postgres;

--
-- TOC entry 51713 (class 0 OID 0)
-- Dependencies: 354
-- Name: TABLE t_obj_attrbd; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbd IS 'Földrészletek II. (nem közterületi)';


--
-- TOC entry 51714 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.parcel_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.parcel_id IS 'Földrészlet azonosító sorszáma a DAT-ban';


--
-- TOC entry 51715 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.obj_fels IS 'Földrészlet objektumféleségének kódja';


--
-- TOC entry 51716 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.felulet_id IS 'A földrészlet geometriáját leíró felület azonosítója';


--
-- TOC entry 51717 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.helyr_szam IS 'A földrészlet helyrajzi száma';


--
-- TOC entry 51718 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.cim_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.cim_id IS 'A földrészlet postacímének kódja';


--
-- TOC entry 51719 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.fekves; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.fekves IS 'Fekvés kódja';


--
-- TOC entry 51720 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.terulet IS 'Számított terület nagysága';


--
-- TOC entry 51721 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.foldert; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.foldert IS 'Földérték';


--
-- TOC entry 51722 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.forg_ertek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.forg_ertek IS 'A földrészlet  szerzéskori forgalmi értéke';


--
-- TOC entry 51723 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.val_nem; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.val_nem IS 'A forgalmi érték valuta neme';


--
-- TOC entry 51724 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.szerv_tip; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.szerv_tip IS 'Szektor';


--
-- TOC entry 51725 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.jogi_jelleg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.jogi_jelleg IS 'Jogi jelleg';


--
-- TOC entry 51726 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.jogallas; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.jogallas IS 'Jogállás';


--
-- TOC entry 51727 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.szemely_id IS 'Vagyonkezelő személy, név- és címadatai (vagy)';


--
-- TOC entry 51728 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.ceg_id IS 'Vagyonkezelő szervezet név- és címadatai (vagy)';


--
-- TOC entry 51729 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51730 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51731 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.elozo_parcel_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.elozo_parcel_id IS 'A földrészlet legutóbb érvényes adatrekordjának azonosítója';


--
-- TOC entry 51732 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.l_datum IS 'Dátum';


--
-- TOC entry 51733 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 51734 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.valt_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.valt_jell IS 'Változási jelleg (pl. egyesítés, megosztás, szolgalmi jog)';


--
-- TOC entry 51735 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.tar_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.tar_hely IS 'Változási vázrajz tárolási helye';


--
-- TOC entry 51736 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.blokk_id IS 'A földrészlet és környezetét dokumentáló légi fénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51737 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51738 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51739 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51740 (class 0 OID 0)
-- Dependencies: 354
-- Name: COLUMN t_obj_attrbd.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbd.pont_id IS 'Földrészlet geokódját kijelölő pont azonosítója';


--
-- TOC entry 355 (class 1259 OID 26631331)
-- Name: bc_bd; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.bc_bd AS
 SELECT bc.parcel_id AS id,
    bc.obj_fels,
    bc.felulet_id,
    bc.helyr_szam,
    bc.cim_id,
    bc.fekves,
    bc.kozter_jell,
    bc.terulet,
    bc.foldert,
    bc.forg_ertek,
    bc.val_nem,
    bc.szerv_tip,
    bc.jogi_jelleg,
    bc.jogallas,
    '-1'::integer AS szemely_id,
    bc.ceg_id,
    bc.elhat_jell,
    bc.elhat_mod,
    bc.elozo_parcel_id AS elozo_id,
    bc.l_datum,
    bc.hatarozat,
    bc.valt_jell,
    bc.tar_hely,
    bc.blokk_id,
    bc.megsz_datum,
    bc.jelkulcs,
    bc.munkater_id,
    bc.pont_id,
    bc.geometria
   FROM datr_sablon.t_obj_attrbc bc
UNION
 SELECT bd.parcel_id AS id,
    bd.obj_fels,
    bd.felulet_id,
    bd.helyr_szam,
    bd.cim_id,
    bd.fekves,
    '-1'::integer AS kozter_jell,
    bd.terulet,
    bd.foldert,
    bd.forg_ertek,
    bd.val_nem,
    bd.szerv_tip,
    bd.jogi_jelleg,
    bd.jogallas,
    bd.szemely_id,
    bd.ceg_id,
    bd.elhat_jell,
    bd.elhat_mod,
    bd.elozo_parcel_id AS elozo_id,
    bd.l_datum,
    bd.hatarozat,
    bd.valt_jell,
    bd.tar_hely,
    bd.blokk_id,
    bd.megsz_datum,
    bd.jelkulcs,
    bd.munkater_id,
    bd.pont_id,
    bd.geometria
   FROM datr_sablon.t_obj_attrbd bd;


ALTER TABLE datr_sablon.bc_bd OWNER TO postgres;

--
-- TOC entry 356 (class 1259 OID 26631336)
-- Name: bc_bd_regi; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.bc_bd_regi AS
 SELECT bc.oid,
    bc.parcel_id AS id,
    bc.obj_fels,
    bc.felulet_id,
    bc.helyr_szam,
    bc.cim_id,
    bc.fekves,
    bc.kozter_jell,
    bc.terulet,
    bc.foldert,
    bc.forg_ertek,
    bc.val_nem,
    bc.szerv_tip,
    bc.jogi_jelleg,
    bc.jogallas,
    '-1'::integer AS szemely_id,
    bc.ceg_id,
    bc.elhat_jell,
    bc.elhat_mod,
    bc.elozo_parcel_id AS elozo_id,
    bc.l_datum,
    bc.hatarozat,
    bc.valt_jell,
    bc.tar_hely,
    bc.blokk_id AS blokk_file,
    bc.megsz_datum,
    bc.jelkulcs,
    bc.munkater_id,
    bc.pont_id,
    bc.geometria
   FROM datr_sablon.t_obj_attrbc bc
UNION
 SELECT bd.oid,
    bd.parcel_id AS id,
    bd.obj_fels,
    bd.felulet_id,
    bd.helyr_szam,
    bd.cim_id,
    bd.fekves,
    '-1'::integer AS kozter_jell,
    bd.terulet,
    bd.foldert,
    bd.forg_ertek,
    bd.val_nem,
    bd.szerv_tip,
    bd.jogi_jelleg,
    bd.jogallas,
    bd.szemely_id,
    bd.ceg_id,
    bd.elhat_jell,
    bd.elhat_mod,
    bd.elozo_parcel_id AS elozo_id,
    bd.l_datum,
    bd.hatarozat,
    bd.valt_jell,
    bd.tar_hely,
    bd.blokk_id AS blokk_file,
    bd.megsz_datum,
    bd.jelkulcs,
    bd.munkater_id,
    bd.pont_id,
    bd.geometria
   FROM datr_sablon.t_obj_attrbd bd;


ALTER TABLE datr_sablon.bc_bd_regi OWNER TO postgres;

SET default_with_oids = false;

--
-- TOC entry 357 (class 1259 OID 26631341)
-- Name: t_felirat; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_felirat (
    id numeric(10,0) NOT NULL,
    felirat_text character varying(256),
    pont_id_text numeric(10,0),
    irany_text numeric(5,1),
    font_id numeric(10,0),
    megsz_datum numeric(8,0),
    tabla_nev character varying(12),
    sor_id numeric(10,0),
    jelleg_kod numeric(4,0),
    geometria public.geometry
);


ALTER TABLE datr_sablon.t_felirat OWNER TO postgres;

--
-- TOC entry 51741 (class 0 OID 0)
-- Dependencies: 357
-- Name: TABLE t_felirat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_felirat IS 'Magyarázó szövegek, feliratok és névrajzi megírások táblázata';


--
-- TOC entry 51742 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.id IS 'A szöveg azonosító sorszáma';


--
-- TOC entry 51743 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.felirat_text; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.felirat_text IS 'A szöveg tartalma';


--
-- TOC entry 51744 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.pont_id_text; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.pont_id_text IS 'A szöveg első karakterének bal alsó sarkához tartozó beszúrási pont koordinátáit tartalmazó rekord azonosítója';


--
-- TOC entry 51745 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.irany_text; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.irany_text IS 'A megírás iránya É-hoz képest';


--
-- TOC entry 51746 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.font_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.font_id IS 'Az alkalmazandó betűtípus és -méretek azonosító kódja';


--
-- TOC entry 51747 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51748 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.tabla_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.tabla_nev IS 'A hivatkozó táblázat neve';


--
-- TOC entry 51749 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.sor_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.sor_id IS 'A hivatkozó táblázat sorának azonosító sorszáma a DAT-ban';


--
-- TOC entry 51750 (class 0 OID 0)
-- Dependencies: 357
-- Name: COLUMN t_felirat.jelleg_kod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat.jelleg_kod IS 'A felirat használatának jellegére utal';


SET default_with_oids = true;

--
-- TOC entry 358 (class 1259 OID 26631347)
-- Name: t_pont; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_pont (
    pont_id numeric(8,0) NOT NULL,
    pont_x numeric(10,3),
    pont_y numeric(10,3),
    pont_h numeric(8,3),
    kozephiba_oszt_v numeric(5,0),
    kozephiba_oszt_m numeric(5,0),
    geometria public.geometry
);


ALTER TABLE datr_sablon.t_pont OWNER TO postgres;

--
-- TOC entry 51751 (class 0 OID 0)
-- Dependencies: 358
-- Name: TABLE t_pont; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_pont IS 'Pont geometriai alapelemek táblázata';


--
-- TOC entry 51752 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN t_pont.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_pont.pont_id IS 'A pont geometriai alapelem azonosítója';


--
-- TOC entry 51753 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN t_pont.pont_x; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_pont.pont_x IS 'A pont EOV x koordinátája';


--
-- TOC entry 51754 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN t_pont.pont_y; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_pont.pont_y IS 'A pont EOV y koordinátája';


--
-- TOC entry 51755 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN t_pont.pont_h; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_pont.pont_h IS 'A pont EOMA magassága';


--
-- TOC entry 51756 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN t_pont.kozephiba_oszt_v; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_pont.kozephiba_oszt_v IS 'A pont által képviselt vízszintes vagy háromdimenziós alappont, vagy síkrajzi részletpont melyik pontossági osztályba tartozik';


--
-- TOC entry 51757 (class 0 OID 0)
-- Dependencies: 358
-- Name: COLUMN t_pont.kozephiba_oszt_m; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_pont.kozephiba_oszt_m IS 'A pont által képviselt magassági alappont, vagy magassági részletpont melyik pontossági osztályba tartozik';


--
-- TOC entry 359 (class 1259 OID 26631353)
-- Name: beszurasi_pont_nelkuli_feliratok; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.beszurasi_pont_nelkuli_feliratok AS
 SELECT f.felirat_text,
    f.pont_id_text
   FROM datr_sablon.t_felirat f
  WHERE (NOT (f.pont_id_text IN ( SELECT p.pont_id
           FROM datr_sablon.t_pont p)));


ALTER TABLE datr_sablon.beszurasi_pont_nelkuli_feliratok OWNER TO postgres;

SET default_with_oids = false;

--
-- TOC entry 360 (class 1259 OID 26631357)
-- Name: t_cim; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_cim (
    cim_id numeric(10,0),
    posta_ir numeric(4,0),
    telepules_id numeric(4,0),
    kozter_nev numeric(12,0),
    kozter_jell numeric(4,0),
    hazsztol character varying(15),
    hazszig character varying(6),
    betutol character varying(6),
    betuig character varying(6),
    lepcsohaz character varying(2),
    emelet numeric(2,0),
    felemelet numeric(1,0),
    szint_id numeric(10,0),
    ajtosz numeric(3,0),
    ajtob character varying(1),
    cimkul_id numeric(10,0),
    elozo_id numeric(10,0),
    erv_datum numeric(8,0),
    megsz_datum numeric(8,0),
    epjel character varying(2),
    pont_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_cim OWNER TO postgres;

--
-- TOC entry 51758 (class 0 OID 0)
-- Dependencies: 360
-- Name: TABLE t_cim; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_cim IS 'Postacímek táblázata';


--
-- TOC entry 361 (class 1259 OID 26631360)
-- Name: t_kozter_jell; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_kozter_jell (
    kozter_jell numeric(4,0),
    ertek character varying(30),
    jelleg_kod numeric(4,0)
);


ALTER TABLE datr_sablon.t_kozter_jell OWNER TO postgres;

--
-- TOC entry 51759 (class 0 OID 0)
-- Dependencies: 361
-- Name: TABLE t_kozter_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_kozter_jell IS '+-> Közterület jelleg kódtáblázata';


--
-- TOC entry 362 (class 1259 OID 26631363)
-- Name: t_kozter_nev; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_kozter_nev (
    kozter_nev numeric(12,0),
    ertek character varying(60)
);


ALTER TABLE datr_sablon.t_kozter_nev OWNER TO postgres;

--
-- TOC entry 51760 (class 0 OID 0)
-- Dependencies: 362
-- Name: TABLE t_kozter_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_kozter_nev IS '+-> Közterület nevek kódtáblázata';


--
-- TOC entry 363 (class 1259 OID 26631366)
-- Name: cimek; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.cimek AS
 SELECT c.cim_id,
    c.posta_ir,
    c.telepules_id,
    c.kozter_nev,
    c.kozter_jell,
    c.hazsztol,
    c.hazszig,
    c.betutol,
    c.betuig,
    c.lepcsohaz,
    c.emelet,
    c.felemelet,
    c.szint_id,
    c.ajtosz,
    c.ajtob,
    c.cimkul_id,
    c.elozo_id,
    c.erv_datum,
    c.megsz_datum,
    j.ertek AS kozter_jell_ertek,
    n.kozter_nev AS kozter_nev_ertek
   FROM datr_sablon.t_cim c,
    datr_sablon.t_kozter_jell j,
    datr_sablon.t_kozter_nev n
  WHERE ((c.kozter_nev = n.kozter_nev) AND (c.kozter_jell = j.kozter_jell));


ALTER TABLE datr_sablon.cimek OWNER TO postgres;

--
-- TOC entry 51761 (class 0 OID 0)
-- Dependencies: 363
-- Name: VIEW cimek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON VIEW datr_sablon.cimek IS 'A címek összeállítása';


--
-- TOC entry 607 (class 1259 OID 188629748)
-- Name: dupla_hrsz; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.dupla_hrsz AS
 SELECT a.oid AS a_oid,
    b.oid AS b_oid,
    a.fekves,
    a.helyr_szam,
    a.obj_fels AS a_obj_fels,
    b.obj_fels AS b_obj_fels
   FROM datr_sablon.bc_bd_regi a,
    datr_sablon.bc_bd_regi b
  WHERE ((a.fekves = b.fekves) AND ((a.helyr_szam)::text = (b.helyr_szam)::text) AND (a.oid <> b.oid));


ALTER TABLE datr_sablon.dupla_hrsz OWNER TO postgres;

--
-- TOC entry 364 (class 1259 OID 26631375)
-- Name: dupla_pont_id; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.dupla_pont_id AS
 SELECT a.pont_id
   FROM datr_sablon.t_pont a,
    datr_sablon.t_pont b
  WHERE ((a.pont_id = b.pont_id) AND (a.oid <> b.oid));


ALTER TABLE datr_sablon.dupla_pont_id OWNER TO postgres;

SET default_with_oids = true;

--
-- TOC entry 365 (class 1259 OID 26631379)
-- Name: t_vonal; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_vonal (
    vonal_id numeric(10,0) NOT NULL,
    vsub_id numeric(8,0) NOT NULL,
    pont_id_1 numeric(8,0),
    pont_id_2 numeric(8,0),
    osszekot_mod numeric(1,0),
    osszekot_id numeric(5,0)
);


ALTER TABLE datr_sablon.t_vonal OWNER TO postgres;

--
-- TOC entry 51762 (class 0 OID 0)
-- Dependencies: 365
-- Name: TABLE t_vonal; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_vonal IS 'Vonalt geometriai alapelemek táblázata';


--
-- TOC entry 51763 (class 0 OID 0)
-- Dependencies: 365
-- Name: COLUMN t_vonal.vonal_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_vonal.vonal_id IS 'A két vagy több pontból álló vonal azonosítója';


--
-- TOC entry 51764 (class 0 OID 0)
-- Dependencies: 365
-- Name: COLUMN t_vonal.vsub_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_vonal.vsub_id IS 'Alazonosító sorszám az egy vonalat alkotó pontpárok megkülönböztetésére';


--
-- TOC entry 51765 (class 0 OID 0)
-- Dependencies: 365
-- Name: COLUMN t_vonal.pont_id_1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_vonal.pont_id_1 IS 'Az első pont azonosítója';


--
-- TOC entry 51766 (class 0 OID 0)
-- Dependencies: 365
-- Name: COLUMN t_vonal.pont_id_2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_vonal.pont_id_2 IS 'A második pont azonosítója';


--
-- TOC entry 51767 (class 0 OID 0)
-- Dependencies: 365
-- Name: COLUMN t_vonal.osszekot_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_vonal.osszekot_mod IS 'A két pont összekötési módjának kódja';


--
-- TOC entry 51768 (class 0 OID 0)
-- Dependencies: 365
-- Name: COLUMN t_vonal.osszekot_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_vonal.osszekot_id IS 'Az összekötés leíró adatainak azonosítója az összekötés módjának megfelelő táblázatban (ha egyenes, akkor NULL)';


--
-- TOC entry 366 (class 1259 OID 26631382)
-- Name: dupla_vonal_id; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.dupla_vonal_id AS
 SELECT a.vonal_id
   FROM datr_sablon.t_vonal a,
    datr_sablon.t_vonal b
  WHERE ((a.vonal_id = b.vonal_id) AND (a.oid <> b.oid));


ALTER TABLE datr_sablon.dupla_vonal_id OWNER TO postgres;

--
-- TOC entry 606 (class 1259 OID 188629744)
-- Name: eltero_hrsz; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.eltero_hrsz AS
 SELECT b.helyr_szam,
    f.felirat_text
   FROM datr_sablon.t_felirat f,
    datr_sablon.bc_bd b
  WHERE ((f.jelleg_kod = (11)::numeric) AND ((b.helyr_szam)::text <> (f.felirat_text)::text) AND (b.geometria OPERATOR(public.&&) f.geometria) AND public.st_contains(b.geometria, f.geometria))
  ORDER BY b.helyr_szam, f.felirat_text;


ALTER TABLE datr_sablon.eltero_hrsz OWNER TO postgres;

--
-- TOC entry 608 (class 1259 OID 188629756)
-- Name: feliratok_beszurasi_pontja; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.feliratok_beszurasi_pontja AS
 SELECT f.felirat_text,
    f.irany_text,
    f.jelleg_kod,
    p.pont_y,
    p.pont_x,
    public.st_geomfromtext((((('POINT('::text || (p.pont_y)::text) || ' '::text) || (p.pont_x)::text) || ')'::text), 23700) AS geometria
   FROM datr_sablon.t_felirat f,
    datr_sablon.t_pont p
  WHERE (f.pont_id_text = p.pont_id);


ALTER TABLE datr_sablon.feliratok_beszurasi_pontja OWNER TO postgres;

SET default_with_oids = false;

--
-- TOC entry 367 (class 1259 OID 26631394)
-- Name: t_hatar; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_hatar (
    hatar_id numeric(8,0) NOT NULL,
    hsub_id numeric(8,0) NOT NULL,
    hatarvonal_id numeric(8,0),
    irany_valt character varying(1)
);


ALTER TABLE datr_sablon.t_hatar OWNER TO postgres;

--
-- TOC entry 51769 (class 0 OID 0)
-- Dependencies: 367
-- Name: TABLE t_hatar; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_hatar IS 'Határ geometriai alapelemek táblázata';


--
-- TOC entry 51770 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN t_hatar.hatar_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatar.hatar_id IS 'Felület határát képező geometriai elem azonosító sorszáma';


--
-- TOC entry 51771 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN t_hatar.hsub_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatar.hsub_id IS 'Alazonosító sorszám az egy határt alkotó határvonalak megkülönböztetésére';


--
-- TOC entry 51772 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN t_hatar.hatarvonal_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatar.hatarvonal_id IS 'Az alkotó határvonal azonosító sorszáma';


--
-- TOC entry 51773 (class 0 OID 0)
-- Dependencies: 367
-- Name: COLUMN t_hatar.irany_valt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatar.irany_valt IS 'A határvonal irányának igazítása a határ alapirányához';


--
-- TOC entry 368 (class 1259 OID 26631397)
-- Name: t_hatarvonal; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_hatarvonal (
    hatarvonal_id numeric(8,0) NOT NULL,
    hvsub_id numeric(8,0) NOT NULL,
    pont_id_1 numeric(8,0),
    pont_id_2 numeric(8,0),
    osszekot_mod numeric(1,0),
    osszekot_id numeric(5,0),
    geometria public.geometry
);


ALTER TABLE datr_sablon.t_hatarvonal OWNER TO postgres;

--
-- TOC entry 51774 (class 0 OID 0)
-- Dependencies: 368
-- Name: TABLE t_hatarvonal; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_hatarvonal IS 'Határvonal geometriai alapelemek táblázata';


--
-- TOC entry 51775 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN t_hatarvonal.hatarvonal_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatarvonal.hatarvonal_id IS 'A két vagy több pontból álló határvonal azonosítója';


--
-- TOC entry 51776 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN t_hatarvonal.hvsub_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatarvonal.hvsub_id IS 'Alazonosító sorszám az egy határvonalat alkotó pontpárok (szakaszok) megkülönböztetésére';


--
-- TOC entry 51777 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN t_hatarvonal.pont_id_1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatarvonal.pont_id_1 IS 'Az első pont azonosítója';


--
-- TOC entry 51778 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN t_hatarvonal.pont_id_2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatarvonal.pont_id_2 IS 'A második pont azonosítója';


--
-- TOC entry 51779 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN t_hatarvonal.osszekot_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatarvonal.osszekot_mod IS 'A két pont összekötési módjának kódja';


--
-- TOC entry 51780 (class 0 OID 0)
-- Dependencies: 368
-- Name: COLUMN t_hatarvonal.osszekot_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_hatarvonal.osszekot_id IS 'Az összekötés leíró adatainak azonosítója az összekötés módjának megfelelő táblázatban (ha egyenes, akkor NULL)';


--
-- TOC entry 369 (class 1259 OID 26631403)
-- Name: hatarok_kozott_nem_szereplo_hatarvonalak; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.hatarok_kozott_nem_szereplo_hatarvonalak AS
 SELECT hv.hatarvonal_id,
    hv.hvsub_id,
    hv.pont_id_1,
    hv.pont_id_2,
    hv.osszekot_mod,
    hv.osszekot_id,
    hv.geometria,
    p1.pont_id AS p1_pont_id,
    p1.pont_x AS p1_pont_x,
    p1.pont_y AS p1_pont_y,
    p1.pont_h AS p1_pont_h,
    p1.kozephiba_oszt_v AS p1_kozephiba_oszt_v,
    p1.kozephiba_oszt_m AS p1_kozephiba_oszt_m,
    p1.geometria AS p1_geometria,
    p2.pont_id AS p2_pont_id,
    p2.pont_x AS p2_pont_x,
    p2.pont_y AS p2_pont_y,
    p2.pont_h AS p2_pont_h,
    p2.kozephiba_oszt_v AS p2_kozephiba_oszt_v,
    p2.kozephiba_oszt_m AS p2_kozephiba_oszt_m,
    p2.geometria AS p2_geometria
   FROM datr_sablon.t_hatarvonal hv,
    datr_sablon.t_pont p1,
    datr_sablon.t_pont p2
  WHERE ((hv.hatarvonal_id IN ( SELECT t_hatarvonal.hatarvonal_id
           FROM datr_sablon.t_hatarvonal
        EXCEPT
         SELECT t_hatar.hatarvonal_id
           FROM datr_sablon.t_hatar)) AND (hv.pont_id_1 = p1.pont_id) AND (hv.pont_id_2 = p2.pont_id));


ALTER TABLE datr_sablon.hatarok_kozott_nem_szereplo_hatarvonalak OWNER TO postgres;

--
-- TOC entry 370 (class 1259 OID 26631408)
-- Name: keress_elt; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.keress_elt AS
 SELECT datr_sablon.find_el_id(datr_sablon.find_hatarvonal_id(datr_sablon.find_pont_id(143509.64, 636848.99))) AS find_el_id;


ALTER TABLE datr_sablon.keress_elt OWNER TO postgres;

--
-- TOC entry 371 (class 1259 OID 26631412)
-- Name: keress_feluletet; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.keress_feluletet AS
 SELECT datr_sablon.find_felulet_id(datr_sablon.find_hatar_id(datr_sablon.find_hatarvonal_id(datr_sablon.find_pont_id(143509.64, 636848.99)))) AS find_felulet_id;


ALTER TABLE datr_sablon.keress_feluletet OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 26631416)
-- Name: keress_gyurut; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.keress_gyurut AS
 SELECT datr_sablon.find_gyuru_id(datr_sablon.find_hatar_id(datr_sablon.find_hatarvonal_id(datr_sablon.find_pont_id(143509.64, 636848.99)))) AS find_gyuru_id;


ALTER TABLE datr_sablon.keress_gyurut OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 26631420)
-- Name: t_felulet; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_felulet (
    felulet_id numeric(8,0) NOT NULL,
    subfel_id numeric(8,0) NOT NULL,
    hatar_id numeric(8,0) NOT NULL,
    hatar_valt character varying(1) NOT NULL,
    geometria public.geometry
);


ALTER TABLE datr_sablon.t_felulet OWNER TO postgres;

--
-- TOC entry 51781 (class 0 OID 0)
-- Dependencies: 373
-- Name: TABLE t_felulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_felulet IS 'Felület geometriai alapelemek táblázata';


--
-- TOC entry 51782 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN t_felulet.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felulet.felulet_id IS 'Az egy vagy több külső határral és külső határonként nulla vagy több belső határral határolt felület azonosító sorszáma';


--
-- TOC entry 51783 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN t_felulet.subfel_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felulet.subfel_id IS 'Alazonosító sorszám a felületet alkotó valamely külső határ (és annak belső határai) megkülönböztetésére az ugyanazt a felületet alkotó többi külső határtól (és azok külső határaitól)';


--
-- TOC entry 51784 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN t_felulet.hatar_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felulet.hatar_id IS 'Az alkotó határ azonosító sorszáma';


--
-- TOC entry 51785 (class 0 OID 0)
-- Dependencies: 373
-- Name: COLUMN t_felulet.hatar_valt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felulet.hatar_valt IS 'A határ irányítottságának igazítása a külső vagy a belső határ fogalmához';


--
-- TOC entry 374 (class 1259 OID 26631426)
-- Name: obj_attr_bc_bd; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attr_bc_bd AS
 SELECT o.oid,
    o.id,
    o.obj_fels,
    o.felulet_id,
    o.helyr_szam,
    o.cim_id,
    o.fekves,
    o.kozter_jell,
    o.terulet,
    o.foldert,
    o.forg_ertek,
    o.val_nem,
    o.szerv_tip,
    o.jogi_jelleg,
    o.jogallas,
    o.szemely_id,
    o.ceg_id,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_id,
    o.l_datum,
    o.hatarozat,
    o.valt_jell,
    o.tar_hely,
    o.blokk_file,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    f.geometria
   FROM (( SELECT bc.oid,
            bc.parcel_id AS id,
            bc.obj_fels,
            bc.felulet_id,
            bc.helyr_szam,
            bc.cim_id,
            bc.fekves,
            bc.kozter_jell,
            bc.terulet,
            bc.foldert,
            bc.forg_ertek,
            bc.val_nem,
            bc.szerv_tip,
            bc.jogi_jelleg,
            bc.jogallas,
            '-1'::integer AS szemely_id,
            bc.ceg_id,
            bc.elhat_jell,
            bc.elhat_mod,
            bc.elozo_parcel_id AS elozo_id,
            bc.l_datum,
            bc.hatarozat,
            bc.valt_jell,
            bc.tar_hely,
            bc.blokk_id AS blokk_file,
            bc.megsz_datum,
            bc.jelkulcs,
            bc.munkater_id,
            bc.pont_id
           FROM datr_sablon.t_obj_attrbc bc
        UNION
         SELECT bd.oid,
            bd.parcel_id AS id,
            bd.obj_fels,
            bd.felulet_id,
            bd.helyr_szam,
            bd.cim_id,
            bd.fekves,
            '-1'::integer AS kozter_jell,
            bd.terulet,
            bd.foldert,
            bd.forg_ertek,
            bd.val_nem,
            bd.szerv_tip,
            bd.jogi_jelleg,
            bd.jogallas,
            bd.szemely_id,
            bd.ceg_id,
            bd.elhat_jell,
            bd.elhat_mod,
            bd.elozo_parcel_id AS elozo_id,
            bd.l_datum,
            bd.hatarozat,
            bd.valt_jell,
            bd.tar_hely,
            bd.blokk_id AS blokk_file,
            bd.megsz_datum,
            bd.jelkulcs,
            bd.munkater_id,
            bd.pont_id
           FROM datr_sablon.t_obj_attrbd bd) o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attr_bc_bd OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 26631431)
-- Name: t_obj_attrba; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrba (
    kozig_idba numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    kozig_id numeric(10,0),
    kozig_kp numeric(10,0),
    ceg_id numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    nemz_nev1 character varying(20),
    nemz_nev2 character varying(20),
    elozo_kozig_id numeric(10,0),
    blokk_id1 numeric(10,0),
    blokk_id2 numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0),
    becsl_jaras numeric(3,0)
);


ALTER TABLE datr_sablon.t_obj_attrba OWNER TO postgres;

--
-- TOC entry 51786 (class 0 OID 0)
-- Dependencies: 375
-- Name: TABLE t_obj_attrba; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrba IS 'Közigazgatási egységek';


--
-- TOC entry 51787 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.kozig_idba; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.kozig_idba IS 'Közigazgatási egység azonosító sorszáma a táblázatban';


--
-- TOC entry 51788 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.obj_fels IS 'Közigazgatási egység objektumféleségének kódja';


--
-- TOC entry 51789 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 51790 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.kozig_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.kozig_id IS 'A közigazgatási egység azonosítója a KSH kódtáblázatban (KSH, NUTS, érvényesség, megszűnés)';


--
-- TOC entry 51791 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.kozig_kp; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.kozig_kp IS 'A közigazgatási központként szolgáló város azonosítója a KSH kódtáblázatban (állam és megye esetén)';


--
-- TOC entry 51792 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.ceg_id IS 'Közigazgatást ellátó szervezet név- és címadatai';


--
-- TOC entry 51793 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51794 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51795 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.nemz_nev1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.nemz_nev1 IS 'A település egyik nemzetiségi neve (csak település esetén)';


--
-- TOC entry 51796 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.nemz_nev2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.nemz_nev2 IS 'A település másik nemzetiségi neve (csak település esetén)';


--
-- TOC entry 51797 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.elozo_kozig_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.elozo_kozig_id IS 'A közigazgatási egység legutóbbi érvényességű adatrekord-jának azonosítója';


--
-- TOC entry 51798 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.blokk_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.blokk_id1 IS 'A közigazgatási egységet bemutató légifénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51799 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.blokk_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.blokk_id2 IS 'A közigazgatási egységet bemutató légifénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51800 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.megsz_datum IS 'Az adatrekord megszűnése érvényességének dátuma';


--
-- TOC entry 51801 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51802 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51803 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.pont_id IS 'Közigazgatási központ (országház, megyei ill. települési önkormányzati központ) főbejáratának geokódját kijelölő pont azonosítója';


--
-- TOC entry 51804 (class 0 OID 0)
-- Dependencies: 375
-- Name: COLUMN t_obj_attrba.becsl_jaras; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrba.becsl_jaras IS 'A becslőjárás kódja';


--
-- TOC entry 376 (class 1259 OID 26631434)
-- Name: obj_attrba; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrba AS
 SELECT o.kozig_idba AS id,
    o.obj_fels,
    o.felulet_id,
    o.kozig_id,
    o.kozig_kp,
    o.ceg_id,
    o.elhat_jell,
    o.elhat_mod,
    o.nemz_nev1,
    o.nemz_nev2,
    o.elozo_kozig_id AS elozo_id,
    o.blokk_id1,
    o.blokk_id2,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    f.geometria
   FROM (datr_sablon.t_obj_attrba o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrba OWNER TO postgres;

--
-- TOC entry 377 (class 1259 OID 26631439)
-- Name: t_obj_attrbb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbb (
    kozigal_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    kozigal_nev character varying(20),
    kozig_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_kozigal_id numeric(10,0),
    blokk_id1 numeric(10,0),
    blokk_id2 numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrbb OWNER TO postgres;

--
-- TOC entry 51805 (class 0 OID 0)
-- Dependencies: 377
-- Name: TABLE t_obj_attrbb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbb IS 'Közigazgatási alegységek';


--
-- TOC entry 51806 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.kozigal_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.kozigal_id IS 'Közigazgatási alegység azonosító sorszáma a DAT-ban';


--
-- TOC entry 51807 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.obj_fels IS 'Közigazgatási alegység objektumféleségének kódja';


--
-- TOC entry 51808 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 51809 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.kozigal_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.kozigal_nev IS 'Közigazgatási alegység neve';


--
-- TOC entry 51810 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.kozig_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.kozig_id IS 'Befoglaló település azonosító sorszáma';


--
-- TOC entry 51811 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.l_datum IS 'A közigazgatási alegység létrejöttének dátuma';


--
-- TOC entry 51812 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.hatarozat IS 'A közigazgatási alegység létrejöttét regisztráló határozat iktatási száma';


--
-- TOC entry 51813 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51814 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51815 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.elozo_kozigal_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.elozo_kozigal_id IS 'A közigazgatási alegység legutóbbi érvényességű adatrekordja';


--
-- TOC entry 51816 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.blokk_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.blokk_id1 IS 'A közigazgatási alegységet bemutató légi fénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51817 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.blokk_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.blokk_id2 IS 'A közigazgatási alegységet bemutató légi fénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51818 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51819 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51820 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51821 (class 0 OID 0)
-- Dependencies: 377
-- Name: COLUMN t_obj_attrbb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbb.pont_id IS 'Közigazgatási alegység geokódját kijelölő pont azonosítója';


--
-- TOC entry 378 (class 1259 OID 26631442)
-- Name: obj_attrbb; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrbb AS
 SELECT o.kozigal_id AS id,
    o.obj_fels,
    o.felulet_id,
    o.kozigal_nev,
    o.kozig_id,
    o.l_datum,
    o.hatarozat,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_kozigal_id AS elozo_id,
    o.blokk_id1,
    o.blokk_id2,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    f.geometria
   FROM (datr_sablon.t_obj_attrbb o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrbb OWNER TO postgres;

--
-- TOC entry 379 (class 1259 OID 26631447)
-- Name: obj_attrbc; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrbc AS
 SELECT o.parcel_id AS id,
    o.obj_fels,
    o.felulet_id,
    o.helyr_szam,
    o.cim_id,
    o.fekves,
    o.kozter_jell,
    o.terulet,
    o.foldert,
    o.forg_ertek,
    o.val_nem,
    o.szerv_tip,
    o.jogi_jelleg,
    o.jogallas,
    o.ceg_id,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_parcel_id AS elozo_id,
    o.l_datum,
    f.geometria
   FROM (datr_sablon.t_obj_attrbc o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrbc OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 26631452)
-- Name: obj_attrbd; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrbd AS
 SELECT o.parcel_id AS id,
    o.obj_fels,
    o.felulet_id,
    o.helyr_szam,
    o.cim_id,
    o.fekves,
    o.terulet,
    o.foldert,
    o.forg_ertek,
    o.val_nem,
    o.szerv_tip,
    o.jogi_jelleg,
    o.jogallas,
    o.szemely_id,
    o.ceg_id,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_parcel_id AS elozo_id,
    o.l_datum,
    o.hatarozat,
    o.valt_jell,
    o.tar_hely,
    o.blokk_id AS blokk_file,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    f.geometria
   FROM (datr_sablon.t_obj_attrbd o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrbd OWNER TO postgres;

--
-- TOC entry 381 (class 1259 OID 26631457)
-- Name: t_obj_attrbe; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbe (
    alreszlet_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    alator character varying(3),
    helyr_szam character varying(15),
    terulet numeric(12,3),
    foldert numeric(12,3),
    muvel_ag numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_alreszlet_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    valt_jell character varying(20),
    tar_cim character varying(20),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrbe OWNER TO postgres;

--
-- TOC entry 51822 (class 0 OID 0)
-- Dependencies: 381
-- Name: TABLE t_obj_attrbe; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbe IS 'Alrészletek és művelési ágak';


--
-- TOC entry 51823 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.alreszlet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.alreszlet_id IS 'Objektum azonosító sorszáma a DAT-ban ';


--
-- TOC entry 51824 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 51825 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 51826 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.alator; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.alator IS 'Az alrészlet, művelési ág jele';


--
-- TOC entry 51827 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.helyr_szam IS 'A befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 51828 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.terulet IS 'Az alrészlet számított területének nagysága';


--
-- TOC entry 51829 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.foldert; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.foldert IS 'Földérték';


--
-- TOC entry 51830 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.muvel_ag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.muvel_ag IS 'Művelési ág (művelés alól kivett terület is)';


--
-- TOC entry 51831 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51832 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51833 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.elozo_alreszlet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.elozo_alreszlet_id IS 'Az alrészlet előző érvényes adatrekordjának azonosítója';


--
-- TOC entry 51834 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.l_datum IS 'Dátum';


--
-- TOC entry 51835 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 51836 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.valt_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.valt_jell IS 'Változási jelleg (pl. egyesítés, szolgalmi jog)';


--
-- TOC entry 51837 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.tar_cim; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.tar_cim IS 'Változási vázrajz tárolási helye';


--
-- TOC entry 51838 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51839 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51840 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51841 (class 0 OID 0)
-- Dependencies: 381
-- Name: COLUMN t_obj_attrbe.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe.pont_id IS 'Alrészlet geokódját kijelölő pont azonosítója';


--
-- TOC entry 382 (class 1259 OID 26631460)
-- Name: obj_attrbe; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrbe AS
 SELECT o.alreszlet_id AS id,
    o.obj_fels,
    o.felulet_id,
    o.alator,
    o.helyr_szam,
    o.terulet,
    o.foldert,
    o.muvel_ag,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_alreszlet_id AS elozo_id,
    o.l_datum,
    o.hatarozat,
    o.valt_jell,
    o.tar_cim,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    f.geometria
   FROM (datr_sablon.t_obj_attrbe o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrbe OWNER TO postgres;

--
-- TOC entry 383 (class 1259 OID 26631465)
-- Name: t_obj_attrbf; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbf (
    moszt_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    minoseg_oszt numeric(10,0),
    muvel_ag numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_moszt_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0),
    helyr_szam character varying(15),
    terulet numeric(12,3)
);


ALTER TABLE datr_sablon.t_obj_attrbf OWNER TO postgres;

--
-- TOC entry 51842 (class 0 OID 0)
-- Dependencies: 383
-- Name: TABLE t_obj_attrbf; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbf IS 'Termőföld-minőségi osztályok';


--
-- TOC entry 51843 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.moszt_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.moszt_id IS 'A termőföld-minőségi osztállyal fedett terület azonosító sorszáma a DAT-ban';


--
-- TOC entry 51844 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.obj_fels IS 'A termőföld-minőségi osztállyal fedett terület objektumféleségének kódja';


--
-- TOC entry 51845 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 51846 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.minoseg_oszt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.minoseg_oszt IS 'Termőföld-minőségi osztály kódja';


--
-- TOC entry 51847 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.muvel_ag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.muvel_ag IS 'Művelési ág';


--
-- TOC entry 51848 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51849 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51850 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.elozo_moszt_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.elozo_moszt_id IS 'A legutóbb érvényes adatrekord azonosítója';


--
-- TOC entry 51851 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51852 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51853 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51854 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.pont_id IS 'Geokódot kijelölő pont azonosítója';


--
-- TOC entry 51855 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.helyr_szam IS 'A befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 51856 (class 0 OID 0)
-- Dependencies: 383
-- Name: COLUMN t_obj_attrbf.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf.terulet IS 'A termőföld minőségi osztállyal fedett terület számított nagysága';


--
-- TOC entry 384 (class 1259 OID 26631468)
-- Name: obj_attrbf; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrbf AS
 SELECT o.moszt_id AS id,
    o.obj_fels,
    o.felulet_id,
    o.minoseg_oszt,
    o.muvel_ag,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_moszt_id AS elozo_id,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    o.helyr_szam,
    o.terulet,
    f.geometria
   FROM (datr_sablon.t_obj_attrbf o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrbf OWNER TO postgres;

--
-- TOC entry 385 (class 1259 OID 26631473)
-- Name: t_obj_attrbg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbg (
    eoi_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    alator_eoi character varying(4),
    helyr_szam character varying(15),
    cim_id numeric(10,0),
    kozter_jell numeric(10,0),
    terulet numeric(8,0),
    forg_ertek numeric(6,0),
    valuta character varying(3),
    szerv_tip numeric(10,0),
    jogi_jelleg numeric(10,0),
    jogallas numeric(10,0),
    eoi_helyiseg numeric(5,0),
    eoi_tulform numeric(5,0),
    szemely_id numeric(10,0),
    ceg_id numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_eoi_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    valt_jell character varying(20),
    tar_hely character varying(20),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrbg OWNER TO postgres;

--
-- TOC entry 51857 (class 0 OID 0)
-- Dependencies: 385
-- Name: TABLE t_obj_attrbg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbg IS 'Egyéb önálló ingatlanok (EÖI)';


--
-- TOC entry 51858 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.eoi_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.eoi_id IS 'Az EÖI azonosító sorszáma a DAT-ban';


--
-- TOC entry 51859 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.obj_fels IS 'Az EÖI objektumféleségének kódja';


--
-- TOC entry 51860 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.felulet_id IS 'Az EÖI geometriáját leíró felület azonosítója';


--
-- TOC entry 51861 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.alator_eoi; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.alator_eoi IS 'Jel az épület földrészleten belüli jelölésére';


--
-- TOC entry 51862 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.helyr_szam IS 'Az EÖI-t befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 51863 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.cim_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.cim_id IS 'Az EÖI postacímének kódja';


--
-- TOC entry 51864 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.kozter_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.kozter_jell IS 'A közterület jelleg kódja (csak a közterületről nyíló pince EÖI esetén töltendő ki ez az adatmező, egyébként NULL)';


--
-- TOC entry 51865 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.terulet IS 'Az EÖI nyilvántartott területének nagysága';


--
-- TOC entry 51866 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.forg_ertek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.forg_ertek IS 'Az EÖI szerzéskori forgalmi értéke';


--
-- TOC entry 51867 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.valuta; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.valuta IS 'A forgalmi érték valuta neme';


--
-- TOC entry 51868 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.szerv_tip; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.szerv_tip IS 'A szektor, amelyikbe az EÖI tartozik';


--
-- TOC entry 51869 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.jogi_jelleg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.jogi_jelleg IS 'Jogi jelleg';


--
-- TOC entry 51870 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.jogallas; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.jogallas IS 'Jogállás';


--
-- TOC entry 51871 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.eoi_helyiseg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.eoi_helyiseg IS 'Az EÖI helyiség megjelölésének kódja';


--
-- TOC entry 51872 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.eoi_tulform; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.eoi_tulform IS 'Az EÖI tulajdoni formája';


--
-- TOC entry 51873 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.szemely_id IS 'Vagyonkezelő személy, név- és címadatai   ';


--
-- TOC entry 51874 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.ceg_id IS 'Vagyonkezelő szervezet, név- és címadatai  ';


--
-- TOC entry 51875 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 51876 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 51877 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.elozo_eoi_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.elozo_eoi_id IS 'Az EÖI legutóbb érvényes adatrekordjának azonosítója';


--
-- TOC entry 51878 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.l_datum IS 'Dátum';


--
-- TOC entry 51879 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 51880 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.valt_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.valt_jell IS 'Változási jelleg (pl. egyesítés, megosztás, szolgalmi jog)';


--
-- TOC entry 51881 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.tar_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.tar_hely IS 'Változási vázrajz tárolási helye';


--
-- TOC entry 51882 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 51883 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51884 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51885 (class 0 OID 0)
-- Dependencies: 385
-- Name: COLUMN t_obj_attrbg.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg.pont_id IS 'Földrészlet geokódját kijelölő pont azonosítója';


--
-- TOC entry 386 (class 1259 OID 26631476)
-- Name: obj_attrbg; Type: VIEW; Schema: datr_sablon; Owner: postgres
--

CREATE VIEW datr_sablon.obj_attrbg AS
 SELECT o.eoi_id,
    o.obj_fels,
    o.felulet_id,
    o.alator_eoi,
    o.helyr_szam,
    o.cim_id,
    o.kozter_jell,
    o.terulet,
    o.forg_ertek,
    o.valuta,
    o.szerv_tip,
    o.jogi_jelleg,
    o.jogallas,
    o.eoi_helyiseg,
    o.eoi_tulform,
    o.szemely_id,
    o.ceg_id,
    o.elhat_jell,
    o.elhat_mod,
    o.elozo_eoi_id AS elozo_id,
    o.l_datum,
    o.hatarozat,
    o.valt_jell,
    o.tar_hely,
    o.megsz_datum,
    o.jelkulcs,
    o.munkater_id,
    o.pont_id,
    f.geometria
   FROM (datr_sablon.t_obj_attrbg o
     LEFT JOIN datr_sablon.t_felulet f ON ((f.felulet_id = o.felulet_id)));


ALTER TABLE datr_sablon.obj_attrbg OWNER TO postgres;

--
-- TOC entry 387 (class 1259 OID 26631481)
-- Name: t_ahaszn_reg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_ahaszn_reg (
    ahaszn_id numeric(5,0) NOT NULL,
    eredeti_id numeric(5,0),
    verzio numeric(8,0),
    muvelet_id numeric(8,0),
    haszn_korl numeric(1,0),
    obj_csop character varying(2),
    ceg_id numeric(6,0),
    szemely_id numeric(8,0),
    ahaszn_cel character varying(150),
    ahaszn_post character varying(150),
    ahaszn_info character varying(150),
    datum character varying(8)
);


ALTER TABLE datr_sablon.t_ahaszn_reg OWNER TO postgres;

--
-- TOC entry 51886 (class 0 OID 0)
-- Dependencies: 387
-- Name: TABLE t_ahaszn_reg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_ahaszn_reg IS 'Állami alapadatokhoz, alapadatokhoz és háttéradatokhoz szükséges táblázat';


--
-- TOC entry 388 (class 1259 OID 26631484)
-- Name: t_attrbizn; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_attrbizn (
    attrbizn_id numeric(6,0) NOT NULL,
    sub_id numeric(2,0),
    munkater_id numeric(6,0),
    attrfels_n character varying(8),
    attrbizn_n character varying(20)
);


ALTER TABLE datr_sablon.t_attrbizn OWNER TO postgres;

--
-- TOC entry 51887 (class 0 OID 0)
-- Dependencies: 388
-- Name: TABLE t_attrbizn; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_attrbizn IS 'Attribútumféleségek meghatározási bizonytalanságának táblázata';


--
-- TOC entry 389 (class 1259 OID 26631487)
-- Name: t_attrelter; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_attrelter (
    attrelter_id numeric(6,0) NOT NULL,
    sub_id numeric(2,0),
    munkater_id numeric(6,0),
    attrfels_n character varying(8),
    attrelter_n character varying(20)
);


ALTER TABLE datr_sablon.t_attrelter OWNER TO postgres;

--
-- TOC entry 51888 (class 0 OID 0)
-- Dependencies: 389
-- Name: TABLE t_attrelter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_attrelter IS 'Attribútumértékek eltérési minőségadatainak táblázata';


--
-- TOC entry 390 (class 1259 OID 26631490)
-- Name: t_ceg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_ceg (
    ceg_id numeric(10,0),
    eredeti_id numeric(10,0),
    ceg_nev character varying(120),
    ceg_rnev character varying(20),
    szerv_tip numeric(10,0),
    telefon numeric(15,0),
    fax numeric(15,0),
    e_mail character varying(30),
    cim_id numeric(10,0),
    ceg_szerep numeric(10,0),
    elozo_ceg_id numeric(10,0),
    erv_datum numeric(8,0),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_ceg OWNER TO postgres;

--
-- TOC entry 51889 (class 0 OID 0)
-- Dependencies: 390
-- Name: TABLE t_ceg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_ceg IS 'Cégek adatainak táblázata';


--
-- TOC entry 391 (class 1259 OID 26631493)
-- Name: t_cim_kulfold; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_cim_kulfold (
    cimkul_id numeric(10,0),
    cim_kulfold character varying(94),
    elozo_cimkul_id numeric(10,0),
    erv_datum numeric(8,0),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_cim_kulfold OWNER TO postgres;

--
-- TOC entry 51890 (class 0 OID 0)
-- Dependencies: 391
-- Name: TABLE t_cim_kulfold; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_cim_kulfold IS 'Külföldi címek táblázata';


--
-- TOC entry 392 (class 1259 OID 26631496)
-- Name: t_el; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_el (
    el_id numeric(8,0) NOT NULL,
    vonal_id numeric(8,0),
    hatarvonal_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_el OWNER TO postgres;

--
-- TOC entry 51891 (class 0 OID 0)
-- Dependencies: 392
-- Name: TABLE t_el; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_el IS 'Élek táblázata';


--
-- TOC entry 393 (class 1259 OID 26631499)
-- Name: t_eredet; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_eredet (
    tabla_nev character varying(12),
    eredet_id numeric(6,0) NOT NULL,
    munkater_id numeric(6,0)
);


ALTER TABLE datr_sablon.t_eredet OWNER TO postgres;

--
-- TOC entry 51892 (class 0 OID 0)
-- Dependencies: 393
-- Name: TABLE t_eredet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_eredet IS 'Eredet adatminőségi jellemzőinek gyűjtőtáblázata';


--
-- TOC entry 609 (class 1259 OID 188629760)
-- Name: t_felirat_jelleg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_felirat_jelleg (
    kod numeric(4,0) NOT NULL,
    ertek character varying(50),
    font_id numeric(2,0)
);


ALTER TABLE datr_sablon.t_felirat_jelleg OWNER TO postgres;

--
-- TOC entry 51893 (class 0 OID 0)
-- Dependencies: 609
-- Name: TABLE t_felirat_jelleg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_felirat_jelleg IS 'Felirat jellegek kódtáblázata';


--
-- TOC entry 51894 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN t_felirat_jelleg.kod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat_jelleg.kod IS 'Jelleg kód';


--
-- TOC entry 51895 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN t_felirat_jelleg.ertek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat_jelleg.ertek IS 'Érték';


--
-- TOC entry 51896 (class 0 OID 0)
-- Dependencies: 609
-- Name: COLUMN t_felirat_jelleg.font_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_felirat_jelleg.font_id IS 'Fontkészlet azonosító id';


--
-- TOC entry 610 (class 1259 OID 188629766)
-- Name: t_font; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_font (
    kod numeric(2,0) NOT NULL,
    betu_tipus character varying(30),
    nagysag numeric(2,0),
    magassag numeric(4,2)
);


ALTER TABLE datr_sablon.t_font OWNER TO postgres;

--
-- TOC entry 51897 (class 0 OID 0)
-- Dependencies: 610
-- Name: TABLE t_font; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_font IS 'Betűtípusok (fontok) kódtáblázata';


--
-- TOC entry 51898 (class 0 OID 0)
-- Dependencies: 610
-- Name: COLUMN t_font.kod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_font.kod IS 'Fontkészlet azonosító id';


--
-- TOC entry 51899 (class 0 OID 0)
-- Dependencies: 610
-- Name: COLUMN t_font.betu_tipus; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_font.betu_tipus IS 'Betű típus';


--
-- TOC entry 51900 (class 0 OID 0)
-- Dependencies: 610
-- Name: COLUMN t_font.nagysag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_font.nagysag IS 'Nagyság';


--
-- TOC entry 51901 (class 0 OID 0)
-- Dependencies: 610
-- Name: COLUMN t_font.magassag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_font.magassag IS 'Magasság';


--
-- TOC entry 394 (class 1259 OID 26631502)
-- Name: t_gyuru; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_gyuru (
    gyuru_id numeric(8,0) NOT NULL,
    hatar_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_gyuru OWNER TO postgres;

--
-- TOC entry 51902 (class 0 OID 0)
-- Dependencies: 394
-- Name: TABLE t_gyuru; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_gyuru IS 'Gyűrűk táblázata';


--
-- TOC entry 395 (class 1259 OID 26631505)
-- Name: t_helyreall_gy; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_helyreall_gy (
    tabla_nev character varying(12),
    alappont_id numeric(10,0),
    datum numeric(8,0),
    zaradek character varying(100),
    ceg_id numeric(10,0),
    szemely_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_helyreall_gy OWNER TO postgres;

--
-- TOC entry 51903 (class 0 OID 0)
-- Dependencies: 395
-- Name: TABLE t_helyreall_gy; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_helyreall_gy IS 'Alappontok helyreállítási adatainak gyűjtőtáblázata';


--
-- TOC entry 396 (class 1259 OID 26631508)
-- Name: t_helyreall_gyio; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_helyreall_gyio (
    tabla_nev character varying(12),
    pont_szam character varying(20),
    alappont_id numeric(10,0),
    datum numeric(8,0),
    zaradek character varying(100),
    ceg_id numeric(10,0),
    szemely_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_helyreall_gyio OWNER TO postgres;

--
-- TOC entry 51904 (class 0 OID 0)
-- Dependencies: 396
-- Name: TABLE t_helyreall_gyio; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_helyreall_gyio IS 'Iránypontok és őrpontok helyreállítási adatainak gyűjtőtáblázata';


--
-- TOC entry 397 (class 1259 OID 26631511)
-- Name: t_helyszin_gy; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_helyszin_gy (
    tabla_nev character varying(12),
    alappont_id numeric(10,0),
    datum numeric(8,0),
    allapot numeric(10,0),
    allapot_ff numeric(10,0),
    megallapit character varying(100),
    ceg_id numeric(10,0),
    szemely_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_helyszin_gy OWNER TO postgres;

--
-- TOC entry 51905 (class 0 OID 0)
-- Dependencies: 397
-- Name: TABLE t_helyszin_gy; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_helyszin_gy IS 'Alappontok helyszínelési adatainak gyűjtőtáblázata';


--
-- TOC entry 398 (class 1259 OID 26631514)
-- Name: t_helyszin_gyio; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_helyszin_gyio (
    tabla_nev character varying(12),
    pont_szam character varying(20),
    alappont_id numeric(10,0),
    datum numeric(8,0),
    allapot numeric(10,0),
    megallapit character varying(100),
    ceg_id numeric(10,0),
    szemely_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_helyszin_gyio OWNER TO postgres;

--
-- TOC entry 51906 (class 0 OID 0)
-- Dependencies: 398
-- Name: TABLE t_helyszin_gyio; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_helyszin_gyio IS 'Iránypontok és őrpontok helyszínelési adatainak gyűjtőtáblázata';


--
-- TOC entry 399 (class 1259 OID 26631517)
-- Name: t_hiteles; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_hiteles (
    hiteles_id numeric(6,0) NOT NULL,
    munkater_id numeric(6,0),
    munkater_ceg_id numeric(6,0),
    munkater_szemely_id numeric(8,0),
    datum numeric(8,0),
    minosit_bk character varying(46),
    minosit_ceg_id numeric(6,0),
    minosit_szemely_id numeric(8,0),
    kezd_datum numeric(8,0),
    zar_datum numeric(8,0),
    control_q character varying(500),
    megfelel character varying(250),
    minos_tetel character varying(500),
    mita_vizsg1 character varying(250),
    mita_vizsg2 character varying(250),
    mita_vizsg3 character varying(250),
    mita_vizsg4 character varying(250),
    mita_vizsg5 character varying(250),
    mita_vizsg6 character varying(250),
    mita_vizsg7 character varying(250),
    minosit_kk character varying(62),
    hiteles character varying(25),
    hitel_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_hiteles OWNER TO postgres;

--
-- TOC entry 51907 (class 0 OID 0)
-- Dependencies: 399
-- Name: TABLE t_hiteles; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_hiteles IS 'Hitelesítés és állami átvétel adatainak táblázata';


--
-- TOC entry 400 (class 1259 OID 26631523)
-- Name: t_iranypont_gy; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_iranypont_gy (
    tabla_nev character varying(12),
    alappont_id numeric(10,0),
    iranyp_szam character varying(20),
    iranyszog numeric(11,9),
    tavolsag numeric(9,3),
    vizsz_alland numeric(10,0),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_iranypont_gy OWNER TO postgres;

--
-- TOC entry 51908 (class 0 OID 0)
-- Dependencies: 400
-- Name: TABLE t_iranypont_gy; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_iranypont_gy IS 'Vízszintes alappontok iránypontjainak gyűjtőtáblázata';


--
-- TOC entry 401 (class 1259 OID 26631526)
-- Name: t_izolalt; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_izolalt (
    izolalt_id numeric(8,0) NOT NULL,
    pont_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_izolalt OWNER TO postgres;

--
-- TOC entry 51909 (class 0 OID 0)
-- Dependencies: 401
-- Name: TABLE t_izolalt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_izolalt IS 'Izolált csomópontok táblázata';


--
-- TOC entry 402 (class 1259 OID 26631529)
-- Name: t_izolalt_l; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_izolalt_l (
    izolalt_id numeric(8,0) NOT NULL,
    lap_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_izolalt_l OWNER TO postgres;

--
-- TOC entry 51910 (class 0 OID 0)
-- Dependencies: 402
-- Name: TABLE t_izolalt_l; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_izolalt_l IS 'Izolált csomópontok lapokhoz rendelésének táblázata';


--
-- TOC entry 403 (class 1259 OID 26631532)
-- Name: t_konziszt; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_konziszt (
    konziszt_id numeric(6,0) NOT NULL,
    munkater_id numeric(6,0),
    top_konz character varying(150),
    strukt_konz character varying(150),
    geo_jog_harm numeric(5,0)
);


ALTER TABLE datr_sablon.t_konziszt OWNER TO postgres;

--
-- TOC entry 51911 (class 0 OID 0)
-- Dependencies: 403
-- Name: TABLE t_konziszt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_konziszt IS 'Adatkonzisztencia jellemzőinek táblázata';


--
-- TOC entry 404 (class 1259 OID 26631535)
-- Name: t_kozb_cspont; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_kozb_cspont (
    kozb_cspont_id numeric(8,0) NOT NULL,
    pont_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_kozb_cspont OWNER TO postgres;

--
-- TOC entry 51912 (class 0 OID 0)
-- Dependencies: 404
-- Name: TABLE t_kozb_cspont; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_kozb_cspont IS 'Közbenső csomópontok táblázata';


--
-- TOC entry 405 (class 1259 OID 26631538)
-- Name: t_kozb_cspont_el; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_kozb_cspont_el (
    kozb_cspont_id numeric(8,0) NOT NULL,
    el_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_kozb_cspont_el OWNER TO postgres;

--
-- TOC entry 51913 (class 0 OID 0)
-- Dependencies: 405
-- Name: TABLE t_kozb_cspont_el; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_kozb_cspont_el IS 'Közbenső csomópontok élekhez rendelésének táblázata';


--
-- TOC entry 406 (class 1259 OID 26631541)
-- Name: t_kozb_cspont_gy; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_kozb_cspont_gy (
    kozb_cspont_id numeric(8,0) NOT NULL,
    gyuru_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_kozb_cspont_gy OWNER TO postgres;

--
-- TOC entry 51914 (class 0 OID 0)
-- Dependencies: 406
-- Name: TABLE t_kozb_cspont_gy; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_kozb_cspont_gy IS 'Közbenső csomópontok gyűrűkhöz rendelésének táblázata';


--
-- TOC entry 407 (class 1259 OID 26631544)
-- Name: t_ksh_kozig; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_ksh_kozig (
    kozig_id numeric(6,0),
    ksh_kod numeric(11,0),
    kozig_nev character varying(40),
    nuts_kod numeric(6,0),
    datum_erv date,
    datum_megsz date,
    beja_kod numeric(4,0),
    CONSTRAINT t_ksh_kozig_kozig_id_check CHECK (((kozig_id >= (1)::numeric) AND (kozig_id <= (9999)::numeric)))
);


ALTER TABLE datr_sablon.t_ksh_kozig OWNER TO postgres;

--
-- TOC entry 51915 (class 0 OID 0)
-- Dependencies: 407
-- Name: TABLE t_ksh_kozig; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_ksh_kozig IS '+-> Közigazgatási egységek KSH kódtáblázata';


--
-- TOC entry 408 (class 1259 OID 26631548)
-- Name: t_lap; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_lap (
    lap_id numeric(8,0) NOT NULL,
    gyuru_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_lap OWNER TO postgres;

--
-- TOC entry 51916 (class 0 OID 0)
-- Dependencies: 408
-- Name: TABLE t_lap; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_lap IS 'Lapok táblázata';


--
-- TOC entry 409 (class 1259 OID 26631551)
-- Name: t_mas_rendszer_gy; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_mas_rendszer_gy (
    tabla_nev character varying(12),
    alappont_id numeric(10,0),
    mas_pont_szam character varying(20),
    vonatk_rv numeric(10,0),
    vonatk_rm numeric(10,0),
    vetulet numeric(10,0),
    mas_u numeric(12,3),
    mas_v numeric(12,3),
    mas_w numeric(12,3)
);


ALTER TABLE datr_sablon.t_mas_rendszer_gy OWNER TO postgres;

--
-- TOC entry 51917 (class 0 OID 0)
-- Dependencies: 409
-- Name: TABLE t_mas_rendszer_gy; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_mas_rendszer_gy IS 'Más (pl. régi) rendszerű koordináták és magasságok gyűjtőtáblázata';


--
-- TOC entry 410 (class 1259 OID 26631554)
-- Name: t_megsz_datumg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_megsz_datumg (
    tabla_nev character varying(20),
    azonosito_no numeric(8,0),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_megsz_datumg OWNER TO postgres;

--
-- TOC entry 51918 (class 0 OID 0)
-- Dependencies: 410
-- Name: TABLE t_megsz_datumg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_megsz_datumg IS 'Geometriai alapelem adatrekordok érvényessége megszűnésének táblázata';


--
-- TOC entry 51919 (class 0 OID 0)
-- Dependencies: 410
-- Name: COLUMN t_megsz_datumg.tabla_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_megsz_datumg.tabla_nev IS 'A hivatkozó táblázat neve';


--
-- TOC entry 51920 (class 0 OID 0)
-- Dependencies: 410
-- Name: COLUMN t_megsz_datumg.azonosito_no; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_megsz_datumg.azonosito_no IS 'A geometriai alapelem azonosító sorszáma';


--
-- TOC entry 51921 (class 0 OID 0)
-- Dependencies: 410
-- Name: COLUMN t_megsz_datumg.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_megsz_datumg.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 411 (class 1259 OID 26631557)
-- Name: t_megsz_datumt; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_megsz_datumt (
    tabla_nev character varying(20),
    azonosito_no numeric(8,0),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_megsz_datumt OWNER TO postgres;

--
-- TOC entry 51922 (class 0 OID 0)
-- Dependencies: 411
-- Name: TABLE t_megsz_datumt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_megsz_datumt IS 'Topológiai alapelem adatrekordok érvényessége megszűnésének táblázata';


--
-- TOC entry 611 (class 1259 OID 188629783)
-- Name: t_muvel_ag; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_muvel_ag (
    kod numeric(2,0) NOT NULL,
    ertek character varying(50)
);


ALTER TABLE datr_sablon.t_muvel_ag OWNER TO postgres;

--
-- TOC entry 51923 (class 0 OID 0)
-- Dependencies: 611
-- Name: TABLE t_muvel_ag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_muvel_ag IS 'Művelési ágak kódtáblázata';


--
-- TOC entry 51924 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN t_muvel_ag.kod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_muvel_ag.kod IS 'Kód';


--
-- TOC entry 51925 (class 0 OID 0)
-- Dependencies: 611
-- Name: COLUMN t_muvel_ag.ertek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_muvel_ag.ertek IS 'Érték';


--
-- TOC entry 412 (class 1259 OID 26631560)
-- Name: t_obj_attraa; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attraa (
    alappont_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    pont_szam character varying(20),
    pont_id numeric(10,0),
    vizsz_alland1 numeric(10,0),
    pontvedo numeric(10,0),
    vizsz_alland2 numeric(10,0),
    v_mag2 numeric(8,3),
    vizsz_alland3 numeric(10,0),
    v_mag3 numeric(8,3),
    meghat_mod numeric(10,0),
    szemely_id numeric(10,0),
    all_datum numeric(8,0),
    elozo_alappont_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    tar_hely character varying(50),
    digit_hely character varying(50),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pontkod character varying(20)
);


ALTER TABLE datr_sablon.t_obj_attraa OWNER TO postgres;

--
-- TOC entry 51926 (class 0 OID 0)
-- Dependencies: 412
-- Name: TABLE t_obj_attraa; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attraa IS 'Vízszintes és 3D geodéziai alappontok';


--
-- TOC entry 51927 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.alappont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.alappont_id IS 'Alappont azonosító sorszáma a DAT-ban';


--
-- TOC entry 51928 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.obj_fels IS 'Alappont objektumféleségének kódja';


--
-- TOC entry 51929 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.pont_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.pont_szam IS 'EOV pontszám (és pontnév)';


--
-- TOC entry 51930 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.pont_id IS 'Az EOV x és y koordinátákat és az EOMA magasságot tartalmazó pont azonosítója';


--
-- TOC entry 51931 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.vizsz_alland1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.vizsz_alland1 IS 'Vonatkozási pont állandósítási módja';


--
-- TOC entry 51932 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.pontvedo; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.pontvedo IS 'Pontvédő berendezés típusa';


--
-- TOC entry 51933 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.vizsz_alland2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.vizsz_alland2 IS 'Föld alatti pontjel: állandósítási módja';


--
-- TOC entry 51934 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.v_mag2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.v_mag2 IS 'Föld alatti pontjel: magassága';


--
-- TOC entry 51935 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.vizsz_alland3; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.vizsz_alland3 IS 'Föld feletti pontjel: állandósítási módja';


--
-- TOC entry 51936 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.v_mag3; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.v_mag3 IS 'Föld feletti pontjel: magassága';


--
-- TOC entry 51937 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.meghat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.meghat_mod IS 'Meghatározás módja';


--
-- TOC entry 51938 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.szemely_id IS 'Meghatározást végző személy, név- és címadatai';


--
-- TOC entry 51939 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.all_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.all_datum IS 'Állandósítás dátuma';


--
-- TOC entry 51940 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.elozo_alappont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.elozo_alappont_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 51941 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.blokk_id IS 'Az alappontot és környezetét bemutató fénykép raszteres állományának azonosító sorszáma';


--
-- TOC entry 51942 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.megsz_datum IS 'Megszüntetésének dátuma';


--
-- TOC entry 51943 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.tar_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.tar_hely IS 'Helyszínrajz és pontleírás tárolási helye';


--
-- TOC entry 51944 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.digit_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.digit_hely IS 'Az alappont további, digitálisan tárolt adatainak helye';


--
-- TOC entry 51945 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51946 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51947 (class 0 OID 0)
-- Dependencies: 412
-- Name: COLUMN t_obj_attraa.pontkod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attraa.pontkod IS 'A pont pontkódja';


--
-- TOC entry 413 (class 1259 OID 26631563)
-- Name: t_obj_attrab; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrab (
    malapp_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    mpont_szam character varying(20),
    pont_id numeric(10,0),
    mag_alland numeric(10,0),
    mag_allandfa numeric(10,0),
    mag numeric(8,3),
    meghat_mod numeric(10,0),
    szemely_id numeric(10,0),
    all_datum numeric(8,0),
    elozo_malapp_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    tar_hely character varying(50),
    digit_hely character varying(50),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pontkod character varying(20)
);


ALTER TABLE datr_sablon.t_obj_attrab OWNER TO postgres;

--
-- TOC entry 51948 (class 0 OID 0)
-- Dependencies: 413
-- Name: TABLE t_obj_attrab; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrab IS 'Magassági geodéziai alappontok';


--
-- TOC entry 51949 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.malapp_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.malapp_id IS 'Alappont azonosító sorszáma a DAT-ban';


--
-- TOC entry 51950 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.obj_fels IS 'Alappont objektumféleségének kódja';


--
-- TOC entry 51951 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.mpont_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.mpont_szam IS 'EOMA pontszám (és pontnév)';


--
-- TOC entry 51952 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.pont_id IS 'Az EOV x és y koordinátákat és az EOMA magasságot tartalmazó pont azonosítója';


--
-- TOC entry 51953 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.mag_alland; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.mag_alland IS 'Vonatkozási pont állandósítási módja';


--
-- TOC entry 51954 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.mag_allandfa; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.mag_allandfa IS 'Föld alatti pontjelek: állandósítási módja';


--
-- TOC entry 51955 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.mag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.mag IS 'Föld alatti pontjelek: magassága';


--
-- TOC entry 51956 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.meghat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.meghat_mod IS 'Meghatározás módja';


--
-- TOC entry 51957 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.szemely_id IS 'Meghatározást végző személy név- és címadatai';


--
-- TOC entry 51958 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.all_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.all_datum IS 'Állandósítás dátuma';


--
-- TOC entry 51959 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.elozo_malapp_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.elozo_malapp_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 51960 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.blokk_id IS 'Az alappontot és környezetét bemutató fénykép raszteres állományának azonosító sorszáma.';


--
-- TOC entry 51961 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.megsz_datum IS 'Megszüntetésének dátuma';


--
-- TOC entry 51962 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.tar_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.tar_hely IS 'Helyszínrajz és pontleírás tárolási helye';


--
-- TOC entry 51963 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.digit_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.digit_hely IS 'Az alappont további, digitálisan tárolt adatainak helye';


--
-- TOC entry 51964 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51965 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51966 (class 0 OID 0)
-- Dependencies: 413
-- Name: COLUMN t_obj_attrab.pontkod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrab.pontkod IS 'A pont pontkódja';


--
-- TOC entry 414 (class 1259 OID 26631566)
-- Name: t_obj_attrac; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrac (
    rpont_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    pont_szam character varying(20),
    pont_id numeric(10,0),
    reszlet_alland numeric(10,0),
    meghat_mod numeric(10,0),
    meghat_datum numeric(8,0),
    elozo_rpont_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pontkod numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrac OWNER TO postgres;

--
-- TOC entry 51967 (class 0 OID 0)
-- Dependencies: 414
-- Name: TABLE t_obj_attrac; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrac IS 'Részletpontok';


--
-- TOC entry 51968 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.rpont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.rpont_id IS 'Részletpont azonosító sorszáma a DAT-ban';


--
-- TOC entry 51969 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.obj_fels IS 'Részletpont objektumféleségének kódja';


--
-- TOC entry 51970 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.pont_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.pont_szam IS 'Pontszám vagy pontnév';


--
-- TOC entry 51971 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.pont_id IS 'Az EOV x és y koordinátákat és az EOMA magasságot tartalmazó pont azonosítója';


--
-- TOC entry 51972 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.reszlet_alland; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.reszlet_alland IS 'Állandósítás módjának kódja';


--
-- TOC entry 51973 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.meghat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.meghat_mod IS 'Meghatározás módjának kódja';


--
-- TOC entry 51974 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.meghat_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.meghat_datum IS 'Meghatározás időpontja';


--
-- TOC entry 51975 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.elozo_rpont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.elozo_rpont_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 51976 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.megsz_datum IS 'Megszüntetésének időpontja';


--
-- TOC entry 51977 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51978 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 51979 (class 0 OID 0)
-- Dependencies: 414
-- Name: COLUMN t_obj_attrac.pontkod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrac.pontkod IS 'A pont pontkódja';


--
-- TOC entry 415 (class 1259 OID 26631569)
-- Name: t_obj_attrad; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrad (
    cimkoord_id numeric(10,0) NOT NULL,
    obj_fels character varying(4),
    pont_szam character varying(20),
    pontkod character varying(20),
    pont_id numeric(8,0),
    megsz_datum character varying(8),
    jelkulcs numeric(3,0),
    leiras character varying(200),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    ep_id numeric(10,0),
    eoi_id numeric(10,0),
    elozo_cimkoord_id numeric(10,0),
    munkater_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrad OWNER TO postgres;

--
-- TOC entry 51980 (class 0 OID 0)
-- Dependencies: 415
-- Name: TABLE t_obj_attrad; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrad IS 'Címkoordináták és attribútumaik táblázata';


--
-- TOC entry 51981 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.cimkoord_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.cimkoord_id IS 'Címkoordináta azonosító sorszáma';


--
-- TOC entry 51982 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.obj_fels IS 'Objektumféleségének kódja';


--
-- TOC entry 51983 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.pont_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.pont_szam IS 'Pontszám vagy pontnév';


--
-- TOC entry 51984 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.pontkod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.pontkod IS 'A pont kódja';


--
-- TOC entry 51985 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.pont_id IS 'A pont geometriai alapelem azonosítója';


--
-- TOC entry 51986 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.megsz_datum IS 'Megszüntetésének időpontja';


--
-- TOC entry 51987 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 51988 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.leiras; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.leiras IS 'Mire vonatkozik a címkoordináta (lakásszám, főbejárat vagy egyéb, bármilyen hozzáfűznivaló, ami az azonosítást segíti)';


--
-- TOC entry 51989 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.parcel_id1 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 51990 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.parcel_id2 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 51991 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.ep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.ep_id IS 'Épület azonosító sorszáma a DAT-ban';


--
-- TOC entry 51992 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.eoi_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.eoi_id IS 'Az EÖI azonosító sorszáma a DAT-ban';


--
-- TOC entry 51993 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.elozo_cimkoord_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.elozo_cimkoord_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 51994 (class 0 OID 0)
-- Dependencies: 415
-- Name: COLUMN t_obj_attrad.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrad.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 416 (class 1259 OID 26631572)
-- Name: t_obj_attrbe_ujabb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbe_ujabb (
    alreszlet_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    alator character varying(3),
    helyr_szam character varying(15),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    terulet numeric(12,3),
    foldert numeric(12,3),
    muvel_ag numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_alreszlet_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    valt_jell character varying(20),
    tar_cim character varying(20),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrbe_ujabb OWNER TO postgres;

--
-- TOC entry 51995 (class 0 OID 0)
-- Dependencies: 416
-- Name: TABLE t_obj_attrbe_ujabb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbe_ujabb IS 'Alrészletek és művelési ágak';


--
-- TOC entry 51996 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.alreszlet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.alreszlet_id IS 'Objektum azonosító sorszáma a DAT-ban ';


--
-- TOC entry 51997 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 51998 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 51999 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.alator; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.alator IS 'Az alrészlet, művelési ág jele';


--
-- TOC entry 52000 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.helyr_szam IS 'A befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52001 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.parcel_id1 IS ' Befoglaló földrészlet azonosítója';


--
-- TOC entry 52002 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.parcel_id2 IS ' Befoglaló földrészlet azonosítója';


--
-- TOC entry 52003 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.terulet IS 'Az alrészlet számított területének nagysága';


--
-- TOC entry 52004 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.foldert; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.foldert IS 'Földérték';


--
-- TOC entry 52005 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.muvel_ag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.muvel_ag IS 'Művelési ág (művelés alól kivett terület is)';


--
-- TOC entry 52006 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 52007 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 52008 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.elozo_alreszlet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.elozo_alreszlet_id IS 'Az alrészlet előző érvényes adatrekordjának azonosítója';


--
-- TOC entry 52009 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.l_datum IS 'Dátum';


--
-- TOC entry 52010 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 52011 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.valt_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.valt_jell IS 'Változási jelleg (pl. egyesítés, szolgalmi jog)';


--
-- TOC entry 52012 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.tar_cim; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.tar_cim IS 'Változási vázrajz tárolási helye';


--
-- TOC entry 52013 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52014 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52015 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52016 (class 0 OID 0)
-- Dependencies: 416
-- Name: COLUMN t_obj_attrbe_ujabb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbe_ujabb.pont_id IS 'Alrészlet geokódját kijelölő pont azonosítója';


--
-- TOC entry 417 (class 1259 OID 26631575)
-- Name: t_obj_attrbf_ujabb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbf_ujabb (
    moszt_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    minoseg_oszt numeric(10,0),
    muvel_ag numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_moszt_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0),
    helyr_szam character varying(15),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    terulet numeric(12,3)
);


ALTER TABLE datr_sablon.t_obj_attrbf_ujabb OWNER TO postgres;

--
-- TOC entry 52017 (class 0 OID 0)
-- Dependencies: 417
-- Name: TABLE t_obj_attrbf_ujabb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbf_ujabb IS 'Termőföld-minőségi osztályok';


--
-- TOC entry 52018 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.moszt_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.moszt_id IS 'A termőföld-minőségi osztállyal fedett terület azonosító sorszáma a DAT-ban';


--
-- TOC entry 52019 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.obj_fels IS 'A termőföld-minőségi osztállyal fedett terület objektumféleségének kódja';


--
-- TOC entry 52020 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 52021 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.minoseg_oszt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.minoseg_oszt IS 'Termőföld-minőségi osztály kódja';


--
-- TOC entry 52022 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.muvel_ag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.muvel_ag IS 'Művelési ág';


--
-- TOC entry 52023 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 52024 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 52025 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.elozo_moszt_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.elozo_moszt_id IS 'A legutóbb érvényes adatrekord azonosítója';


--
-- TOC entry 52026 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52027 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52028 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52029 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.pont_id IS 'Geokódot kijelölő pont azonosítója';


--
-- TOC entry 52030 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.helyr_szam IS 'A befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52031 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.parcel_id1 IS ' Befoglaló földrészlet azonosítója';


--
-- TOC entry 52032 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.parcel_id2 IS ' Befoglaló földrészlet azonosítója';


--
-- TOC entry 52033 (class 0 OID 0)
-- Dependencies: 417
-- Name: COLUMN t_obj_attrbf_ujabb.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbf_ujabb.terulet IS 'A termőföld minőségi osztállyal fedett terület számított nagysága';


--
-- TOC entry 418 (class 1259 OID 26631578)
-- Name: t_obj_attrbg_ujabb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbg_ujabb (
    eoi_id numeric(10,0) NOT NULL,
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    alator_eoi character varying(4),
    helyr_szam character varying(15),
    cim_id numeric(10,0),
    kozter_jell numeric(10,0),
    terulet numeric(8,0),
    forg_ertek numeric(6,0),
    valuta character varying(3),
    szerv_tip numeric(10,0),
    jogi_jelleg numeric(10,0),
    jogallas numeric(10,0),
    eoi_helyiseg numeric(5,0),
    eoi_tulform numeric(5,0),
    szemely_id numeric(10,0),
    ceg_id numeric(10,0),
    elhat_jell numeric(10,0),
    elhat_mod numeric(10,0),
    elozo_eoi_id numeric(10,0),
    l_datum numeric(8,0),
    hatarozat character varying(20),
    valt_jell character varying(20),
    tar_hely character varying(20),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrbg_ujabb OWNER TO postgres;

--
-- TOC entry 52034 (class 0 OID 0)
-- Dependencies: 418
-- Name: TABLE t_obj_attrbg_ujabb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbg_ujabb IS 'Egyéb önálló ingatlanok (EÖI)';


--
-- TOC entry 52035 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.eoi_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.eoi_id IS 'Az EÖI azonosító sorszáma a DAT-ban';


--
-- TOC entry 52036 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.obj_fels IS 'Az EÖI objektumféleségének kódja';


--
-- TOC entry 52037 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.felulet_id IS 'Az EÖI geometriáját leíró felület azonosítója';


--
-- TOC entry 52038 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.alator_eoi; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.alator_eoi IS 'Jel az épület földrészleten belüli jelölésére';


--
-- TOC entry 52039 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.helyr_szam IS 'Az EÖI-t befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52040 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.cim_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.cim_id IS 'Az EÖI postacímének kódja';


--
-- TOC entry 52041 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.kozter_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.kozter_jell IS 'A közterület jelleg kódja (csak a közterületről nyíló pince EÖI esetén töltendő ki ez az adatmező, egyébként NULL)';


--
-- TOC entry 52042 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.terulet IS 'Az EÖI nyilvántartott területének nagysága';


--
-- TOC entry 52043 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.forg_ertek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.forg_ertek IS 'Az EÖI szerzéskori forgalmi értéke';


--
-- TOC entry 52044 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.valuta; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.valuta IS 'A forgalmi érték valuta neme';


--
-- TOC entry 52045 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.szerv_tip; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.szerv_tip IS 'A szektor, amelyikbe az EÖI tartozik';


--
-- TOC entry 52046 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.jogi_jelleg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.jogi_jelleg IS 'Jogi jelleg';


--
-- TOC entry 52047 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.jogallas; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.jogallas IS 'Jogállás';


--
-- TOC entry 52048 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.eoi_helyiseg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.eoi_helyiseg IS 'Az EÖI helyiség megjelölésének kódja';


--
-- TOC entry 52049 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.eoi_tulform; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.eoi_tulform IS 'Az EÖI tulajdoni formája';


--
-- TOC entry 52050 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.szemely_id IS 'Vagyonkezelő személy, név- és címadatai   ';


--
-- TOC entry 52051 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.ceg_id IS 'Vagyonkezelő szervezet, név- és címadatai  ';


--
-- TOC entry 52052 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.elhat_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.elhat_jell IS 'Elhatárolás jellege';


--
-- TOC entry 52053 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.elhat_mod; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.elhat_mod IS 'Elhatárolás módja';


--
-- TOC entry 52054 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.elozo_eoi_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.elozo_eoi_id IS 'Az EÖI legutóbb érvényes adatrekordjának azonosítója';


--
-- TOC entry 52055 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.l_datum IS 'Dátum';


--
-- TOC entry 52056 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 52057 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.valt_jell; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.valt_jell IS 'Változási jelleg (pl. egyesítés, megosztás, szolgalmi jog)';


--
-- TOC entry 52058 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.tar_hely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.tar_hely IS 'Változási vázrajz tárolási helye';


--
-- TOC entry 52059 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52060 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52061 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52062 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.pont_id IS 'Földrészlet geokódját kijelölő pont azonosítója';


--
-- TOC entry 52063 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.parcel_id1 IS ' Befoglaló földrészlet azonosítója';


--
-- TOC entry 52064 (class 0 OID 0)
-- Dependencies: 418
-- Name: COLUMN t_obj_attrbg_ujabb.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbg_ujabb.parcel_id2 IS ' Befoglaló földrészlet azonosítója';


--
-- TOC entry 419 (class 1259 OID 26631581)
-- Name: t_obj_attrbh; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbh (
    szolg_id numeric(10,0) NOT NULL,
    obj_fels character varying(4),
    obj_kiterj numeric(1,0),
    geo_ae_id numeric(8,0),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    terulet numeric(12,0),
    elozo_szolg_id numeric(10,0),
    l_datum character varying(8),
    hatarozat character varying(20),
    megsz_datum character varying(8),
    jelkulcs numeric(3,0),
    munkater_id numeric(10,0),
    pont_id numeric(8,0),
    megjegyzes character varying(8)
);


ALTER TABLE datr_sablon.t_obj_attrbh OWNER TO postgres;

--
-- TOC entry 52065 (class 0 OID 0)
-- Dependencies: 419
-- Name: TABLE t_obj_attrbh; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbh IS 'Szolgalmi joggal érintett területek és attribútumaik táblázata';


--
-- TOC entry 52066 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.szolg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.szolg_id IS 'azonosító sorszáma a DAT-ban';


--
-- TOC entry 52067 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.obj_fels IS 'objektumféleségének kódja';


--
-- TOC entry 52068 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.obj_kiterj IS '3-felület';


--
-- TOC entry 52069 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.geo_ae_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 52070 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.parcel_id1 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52071 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.parcel_id2 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52072 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.terulet; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.terulet IS 'A szolgalmi joggal érintett terület nagysága';


--
-- TOC entry 52073 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.elozo_szolg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.elozo_szolg_id IS 'A szolgalom legutóbb érvényes adatrekordjának azonosítója';


--
-- TOC entry 52074 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.l_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.l_datum IS 'Dátum';


--
-- TOC entry 52075 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.hatarozat; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.hatarozat IS 'Határozat iktatási száma';


--
-- TOC entry 52076 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.megsz_datum IS 'Adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52077 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.jelkulcs IS 'Jelkulcs kódja';


--
-- TOC entry 52078 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.munkater_id IS 'Felmérési munkaterület azonosítója';


--
-- TOC entry 52079 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.pont_id IS 'A szolgalom geokódját kijelölő pont azonosítója';


--
-- TOC entry 52080 (class 0 OID 0)
-- Dependencies: 419
-- Name: COLUMN t_obj_attrbh.megjegyzes; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbh.megjegyzes IS 'Tetszőleges megjegyzés';


--
-- TOC entry 420 (class 1259 OID 26631584)
-- Name: t_obj_attrbi; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrbi (
    mintater_id numeric(10,0) NOT NULL,
    obj_fels character varying(4),
    obj_kiterj numeric(1,0),
    geo_ae_id numeric(8,0),
    jelleg numeric(1,0),
    helyszin_labor character varying(500),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    helyr_szam character varying(15),
    elozo_mintater_id numeric(10,0),
    minoseg_oszt numeric(2,0),
    muvel_ag numeric(2,0),
    mt_melyseg character varying(15),
    mt_feltalaj character varying(200),
    mt_altalaj character varying(200),
    mt_tulajdonsag character varying(500),
    megsz_datum character varying(8),
    jelkulcs numeric(3,0),
    munkater_id numeric(10,0),
    megjegyzes character varying(200)
);


ALTER TABLE datr_sablon.t_obj_attrbi OWNER TO postgres;

--
-- TOC entry 52081 (class 0 OID 0)
-- Dependencies: 420
-- Name: TABLE t_obj_attrbi; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrbi IS 'Földminősítési mintaterek és attribútumaik táblázata';


--
-- TOC entry 52082 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.mintater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.mintater_id IS 'A mintatér azonosító sorszáma a DAT-ban';


--
-- TOC entry 52083 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.obj_fels IS 'A mintatér objektumféleségének kódja';


--
-- TOC entry 52084 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.obj_kiterj IS '1-pont, 3-felület';


--
-- TOC entry 52085 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_kiterj alapján kiválasztott geometriai táblázatból származik)';


--
-- TOC entry 52086 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.jelleg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.jelleg IS '1-községi mintatér, 2-járási mintatér';


--
-- TOC entry 52087 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.helyszin_labor; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.helyszin_labor IS 'A helyszíni és a laborvizsgálat eredménye';


--
-- TOC entry 52088 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.parcel_id1 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52089 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.parcel_id2 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52090 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.helyr_szam IS 'Befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52091 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.elozo_mintater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.elozo_mintater_id IS 'A mintater legutóbb érvényes adatrekordjának azonosítója';


--
-- TOC entry 52092 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.minoseg_oszt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.minoseg_oszt IS 'Termőföld minőségi osztály kódja';


--
-- TOC entry 52093 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.muvel_ag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.muvel_ag IS 'Művelési ág';


--
-- TOC entry 52094 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.mt_melyseg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.mt_melyseg IS 'A mintatér mélysége';


--
-- TOC entry 52095 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.mt_feltalaj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.mt_feltalaj IS 'A mintatér feltalajának leírása';


--
-- TOC entry 52096 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.mt_altalaj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.mt_altalaj IS 'A mintatér altalajának leírása';


--
-- TOC entry 52097 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.mt_tulajdonsag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.mt_tulajdonsag IS 'A mintatér tulajdonsága';


--
-- TOC entry 52098 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.megsz_datum IS 'Adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52099 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.jelkulcs IS 'Jelkulcs kódja';


--
-- TOC entry 52100 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.munkater_id IS 'Felmérési munkaterület azonosítója';


--
-- TOC entry 52101 (class 0 OID 0)
-- Dependencies: 420
-- Name: COLUMN t_obj_attrbi.megjegyzes; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrbi.megjegyzes IS 'Tetszőleges megjegyzés';


--
-- TOC entry 421 (class 1259 OID 26631587)
-- Name: t_obj_attrca; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrca (
    ep_id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    cim_id numeric(10,0),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    ep_sorsz numeric(5,0),
    szintek numeric(5,0),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    epulet_tip numeric(10,0),
    epulet_alt numeric(10,0),
    szemely_id numeric(10,0),
    ceg_id numeric(10,0),
    elozo_ep_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrca OWNER TO postgres;

--
-- TOC entry 52102 (class 0 OID 0)
-- Dependencies: 421
-- Name: TABLE t_obj_attrca; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrca IS 'Épületek (a D, E és F objektumosztályba sorolhatók is)';


--
-- TOC entry 52103 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.ep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.ep_id IS 'Épület azonosító sorszáma a DAT-ban';


--
-- TOC entry 52104 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.obj_fels IS 'Épület objektumféleségének kódja';


--
-- TOC entry 52105 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.felulet_id IS 'Az épület geometriáját leíró felület azonosítója';


--
-- TOC entry 52106 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.cim_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.cim_id IS 'Az épület postacíme';


--
-- TOC entry 52107 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.parcel_id1 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52108 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.parcel_id2 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52109 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.ep_sorsz; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.ep_sorsz IS 'Az épület földrészleten belüli sorszáma';


--
-- TOC entry 52110 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.szintek; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.szintek IS 'Szintek  száma';


--
-- TOC entry 52111 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.fugg_kiter IS 'Az épület függőleges kiterjedése';


--
-- TOC entry 52112 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.anyag IS 'Az épület jellemző anyagának kódja';


--
-- TOC entry 52113 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.epulet_tip; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.epulet_tip IS 'Az épület ingatlan-nyilvántartás szerinti típusának kódja';


--
-- TOC entry 52114 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.epulet_alt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.epulet_alt IS 'Az épület funkcionális altípusának kódja';


--
-- TOC entry 52115 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.szemely_id IS 'A vagyonkezelő személy, név- és címadatai ';


--
-- TOC entry 52116 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.ceg_id IS 'A vagyonkezelő szervezet, név-  és címadatai';


--
-- TOC entry 52117 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.elozo_ep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.elozo_ep_id IS 'Az épület legutóbbi érvényességű adatrekordjának azonosítója';


--
-- TOC entry 52118 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.blokk_id IS 'Az épületet és környezetét bemutató fénykép vagy vázrajz raszteres állomány azonosító sorszáma';


--
-- TOC entry 52119 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52120 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52121 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52122 (class 0 OID 0)
-- Dependencies: 421
-- Name: COLUMN t_obj_attrca.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrca.pont_id IS 'A főbejáratra vonatkoztatott geokódot kijelölő pont azonosítója';


--
-- TOC entry 422 (class 1259 OID 26631590)
-- Name: t_obj_attrcb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrcb (
    eptart_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    ep_id numeric(10,0),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    elozo_eptart_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrcb OWNER TO postgres;

--
-- TOC entry 52123 (class 0 OID 0)
-- Dependencies: 422
-- Name: TABLE t_obj_attrcb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrcb IS 'Épületek tartozékai (CA objektumféleségek  tartozékai)';


--
-- TOC entry 52124 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.eptart_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.eptart_id IS 'Épülettartozék azonosító sorszáma a DAT-ban';


--
-- TOC entry 52125 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.obj_fels IS 'Épülettartozék objektumféleségének kódja';


--
-- TOC entry 52126 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.obj_kiterj IS 'Az objektum kiterjedése. 1-pont, 2-vonal, 3-felület';


--
-- TOC entry 52127 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_kiterj alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52128 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.ep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.ep_id IS 'Az épülettartozékkal bíró épület azonosító sorszáma';


--
-- TOC entry 52129 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.fugg_kiter IS 'Épülettartozék függőleges kiterjedése';


--
-- TOC entry 52130 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.anyag IS 'Épülettartozék jellemző anyagának kódja';


--
-- TOC entry 52131 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.elozo_eptart_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.elozo_eptart_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52132 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52133 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52134 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52135 (class 0 OID 0)
-- Dependencies: 422
-- Name: COLUMN t_obj_attrcb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcb.pont_id IS 'A geokódot kijelölő pont azonosítója';


--
-- TOC entry 423 (class 1259 OID 26631593)
-- Name: t_obj_attrcc; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrcc (
    kerit_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    helyr_szam character varying(15),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    szemely_id numeric(10,0),
    ceg_id numeric(10,0),
    elozo_kerit_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrcc OWNER TO postgres;

--
-- TOC entry 52136 (class 0 OID 0)
-- Dependencies: 423
-- Name: TABLE t_obj_attrcc; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrcc IS 'Kerítések, támfalak, földművek (a D, E és F objektumosztályba sorolhatók is)';


--
-- TOC entry 52137 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.kerit_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.kerit_id IS 'Objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52138 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 52139 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.obj_kiterj IS 'Az objektum kiterjedése.  2-vonal, 3-felület';


--
-- TOC entry 52140 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_FELS alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik).';


--
-- TOC entry 52141 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.helyr_szam IS 'Az érintett földrészlet helyrajzi száma';


--
-- TOC entry 52142 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.fugg_kiter IS 'Objektum függőleges kiterjedése';


--
-- TOC entry 52143 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.anyag IS 'Objektum jellemző anyagának kódja';


--
-- TOC entry 52144 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.szemely_id IS 'Tulajdonos személy, név- és címadatai ';


--
-- TOC entry 52145 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.ceg_id IS 'Tulajdonos szervezet, név- és címadatai ';


--
-- TOC entry 52146 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.elozo_kerit_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.elozo_kerit_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52147 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52148 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52149 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52150 (class 0 OID 0)
-- Dependencies: 423
-- Name: COLUMN t_obj_attrcc.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc.pont_id IS 'A geokódot kijelölő pont azonosítója (kerítésnél a kapu vagy a főbejárat)';


--
-- TOC entry 424 (class 1259 OID 26631596)
-- Name: t_obj_attrcc_ujabb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrcc_ujabb (
    kerit_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    helyr_szam character varying(15),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    szemely_id numeric(10,0),
    ceg_id numeric(10,0),
    elozo_kerit_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrcc_ujabb OWNER TO postgres;

--
-- TOC entry 52151 (class 0 OID 0)
-- Dependencies: 424
-- Name: TABLE t_obj_attrcc_ujabb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrcc_ujabb IS 'Kerítések, támfalak, földművek (a D, E és F objektumosztályba sorolhatók is)';


--
-- TOC entry 52152 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.kerit_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.kerit_id IS 'Objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52153 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 52154 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.obj_kiterj IS 'Az objektum kiterjedése.  2-vonal, 3-felület';


--
-- TOC entry 52155 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_FELS alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik).';


--
-- TOC entry 52156 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.helyr_szam IS 'Az érintett földrészlet helyrajzi száma';


--
-- TOC entry 52157 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.parcel_id1 IS 'Az érintett földrészlet azonosítója';


--
-- TOC entry 52158 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.parcel_id2 IS 'Az érintett földrészlet azonosítója';


--
-- TOC entry 52159 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.fugg_kiter IS 'Objektum függőleges kiterjedése';


--
-- TOC entry 52160 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.anyag IS 'Objektum jellemző anyagának kódja';


--
-- TOC entry 52161 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.szemely_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.szemely_id IS 'Tulajdonos személy, név- és címadatai ';


--
-- TOC entry 52162 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.ceg_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.ceg_id IS 'Tulajdonos szervezet, név- és címadatai ';


--
-- TOC entry 52163 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.elozo_kerit_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.elozo_kerit_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52164 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52165 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52166 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52167 (class 0 OID 0)
-- Dependencies: 424
-- Name: COLUMN t_obj_attrcc_ujabb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcc_ujabb.pont_id IS 'A geokódot kijelölő pont azonosítója (kerítésnél a kapu vagy a főbejárat)';


--
-- TOC entry 425 (class 1259 OID 26631599)
-- Name: t_obj_attrcd; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrcd (
    terep_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    helyr_szam character varying(15),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    szemely_id1 numeric(10,0),
    ceg_id1 numeric(10,0),
    szemely_id2 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_terep_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrcd OWNER TO postgres;

--
-- TOC entry 52168 (class 0 OID 0)
-- Dependencies: 425
-- Name: TABLE t_obj_attrcd; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrcd IS 'Tereptárgyak, egyedi építmények';


--
-- TOC entry 52169 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.terep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.terep_id IS 'Objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52170 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 52171 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.obj_kiterj IS 'Az objektum kiterjedése. 1-pont, 2-vonal, 3-felület';


--
-- TOC entry 52172 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52173 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.helyr_szam IS 'Befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52174 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.fugg_kiter IS 'Objektum függőleges kiterjedése';


--
-- TOC entry 52175 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.anyag IS 'Objektum jellemző anyagának kódja';


--
-- TOC entry 52176 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.szemely_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.szemely_id1 IS 'Tulajdonos személy, név- és címadatai';


--
-- TOC entry 52177 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai ';


--
-- TOC entry 52178 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.szemely_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.szemely_id2 IS 'Vagyonkezelő személy, név- és címadatai';


--
-- TOC entry 52179 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai ';


--
-- TOC entry 52180 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.elozo_terep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.elozo_terep_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52181 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.blokk_id IS 'Az objektumot és környezetét bemutató fénykép vagy vázrajz raszteres állományának azonosító sorszáma';


--
-- TOC entry 52182 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52183 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52184 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52185 (class 0 OID 0)
-- Dependencies: 425
-- Name: COLUMN t_obj_attrcd.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd.pont_id IS 'A geokódot kijelölő pont azonosítója';


--
-- TOC entry 426 (class 1259 OID 26631602)
-- Name: t_obj_attrcd_ujabb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrcd_ujabb (
    terep_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    helyr_szam character varying(15),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    szemely_id1 numeric(10,0),
    ceg_id1 numeric(10,0),
    szemely_id2 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_terep_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrcd_ujabb OWNER TO postgres;

--
-- TOC entry 52186 (class 0 OID 0)
-- Dependencies: 426
-- Name: TABLE t_obj_attrcd_ujabb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrcd_ujabb IS 'Tereptárgyak, egyedi építmények';


--
-- TOC entry 52187 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.terep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.terep_id IS 'Objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52188 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 52189 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.obj_kiterj IS 'Az objektum kiterjedése. 1-pont, 2-vonal, 3-felület';


--
-- TOC entry 52190 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52191 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.helyr_szam IS 'Befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52192 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.parcel_id1 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52193 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.parcel_id2 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52194 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.fugg_kiter IS 'Objektum függőleges kiterjedése';


--
-- TOC entry 52195 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.anyag IS 'Objektum jellemző anyagának kódja';


--
-- TOC entry 52196 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.szemely_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.szemely_id1 IS 'Tulajdonos személy, név- és címadatai';


--
-- TOC entry 52197 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai ';


--
-- TOC entry 52198 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.szemely_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.szemely_id2 IS 'Vagyonkezelő személy, név- és címadatai';


--
-- TOC entry 52199 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai ';


--
-- TOC entry 52200 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.elozo_terep_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.elozo_terep_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52201 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.blokk_id IS 'Az objektumot és környezetét bemutató fénykép vagy vázrajz raszteres állományának azonosító sorszáma';


--
-- TOC entry 52202 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52203 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52204 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52205 (class 0 OID 0)
-- Dependencies: 426
-- Name: COLUMN t_obj_attrcd_ujabb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrcd_ujabb.pont_id IS 'A geokódot kijelölő pont azonosítója';


--
-- TOC entry 427 (class 1259 OID 26631605)
-- Name: t_obj_attrce; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrce (
    szobor_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    helyr_szam character varying(15),
    kozter_nev numeric(10,0),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_szobor_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrce OWNER TO postgres;

--
-- TOC entry 52206 (class 0 OID 0)
-- Dependencies: 427
-- Name: TABLE t_obj_attrce; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrce IS 'Köztéri szobrok, emlékművek, emlékhelyek';


--
-- TOC entry 52207 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.szobor_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.szobor_id IS 'Objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52208 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 52209 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.obj_kiterj IS 'Az objektum kiterjedése. 1-pont, 3-felület';


--
-- TOC entry 52210 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52211 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.helyr_szam IS 'Befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52212 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.kozter_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.kozter_nev IS 'Befoglaló közterület nevének kódja';


--
-- TOC entry 52213 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.fugg_kiter IS 'Objektum függőleges kiterjedése';


--
-- TOC entry 52214 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.anyag IS 'Objektum jellemző anyagának kódja';


--
-- TOC entry 52215 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52216 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52217 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.elozo_szobor_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.elozo_szobor_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52218 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.blokk_id IS 'Az objektumot és környezetét bemutató fénykép vagy vázrajz raszteres állományának azonosító sorszáma';


--
-- TOC entry 52219 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52220 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52221 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52222 (class 0 OID 0)
-- Dependencies: 427
-- Name: COLUMN t_obj_attrce.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce.pont_id IS 'A geokódot kijelölő pont azonosítója';


--
-- TOC entry 428 (class 1259 OID 26631608)
-- Name: t_obj_attrce_ujabb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrce_ujabb (
    szobor_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    helyr_szam character varying(15),
    parcel_id1 numeric(10,0),
    parcel_id2 numeric(10,0),
    kozter_nev numeric(10,0),
    fugg_kiter numeric(5,0),
    anyag numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_szobor_id numeric(10,0),
    blokk_id character varying(15),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrce_ujabb OWNER TO postgres;

--
-- TOC entry 52223 (class 0 OID 0)
-- Dependencies: 428
-- Name: TABLE t_obj_attrce_ujabb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrce_ujabb IS 'Köztéri szobrok, emlékművek, emlékhelyek';


--
-- TOC entry 52224 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.szobor_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.szobor_id IS 'Objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52225 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.obj_fels IS 'Objektum objektumféleségének kódja';


--
-- TOC entry 52226 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.obj_kiterj IS 'Az objektum kiterjedése. 1-pont, 3-felület';


--
-- TOC entry 52227 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52228 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.helyr_szam; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.helyr_szam IS 'Befoglaló földrészlet helyrajzi száma';


--
-- TOC entry 52229 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.parcel_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.parcel_id1 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52230 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.parcel_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.parcel_id2 IS 'Befoglaló földrészlet azonosítója';


--
-- TOC entry 52231 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.kozter_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.kozter_nev IS 'Befoglaló közterület nevének kódja';


--
-- TOC entry 52232 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.fugg_kiter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.fugg_kiter IS 'Objektum függőleges kiterjedése';


--
-- TOC entry 52233 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.anyag; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.anyag IS 'Objektum jellemző anyagának kódja';


--
-- TOC entry 52234 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52235 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52236 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.elozo_szobor_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.elozo_szobor_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52237 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.blokk_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.blokk_id IS 'Az objektumot és környezetét bemutató fénykép vagy vázrajz raszteres állományának azonosító sorszáma';


--
-- TOC entry 52238 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52239 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52240 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52241 (class 0 OID 0)
-- Dependencies: 428
-- Name: COLUMN t_obj_attrce_ujabb.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrce_ujabb.pont_id IS 'A geokódot kijelölő pont azonosítója';


--
-- TOC entry 429 (class 1259 OID 26631611)
-- Name: t_obj_attrda; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrda (
    kozut_id numeric(10,0),
    obj_fels character varying(10),
    pont_id numeric(10,0),
    szakag_sz character varying(10),
    kozut_az numeric(10,0),
    szak_nev numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_kozut_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0)
);


ALTER TABLE datr_sablon.t_obj_attrda OWNER TO postgres;

--
-- TOC entry 52242 (class 0 OID 0)
-- Dependencies: 429
-- Name: TABLE t_obj_attrda; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrda IS 'Közlekedési létesítmények azonosítópontjai';


--
-- TOC entry 52243 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.kozut_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.kozut_id IS 'Azonosítópont azonosító sorszáma a DAT-ban';


--
-- TOC entry 52244 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.obj_fels IS 'Azonosítópont objektumféleség kódja';


--
-- TOC entry 52245 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.pont_id IS 'Az objektumot kijelölő pont azonosítója';


--
-- TOC entry 52246 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.szakag_sz; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.szakag_sz IS 'Szakági pontszáma vagy neve';


--
-- TOC entry 52247 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.kozut_az; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.kozut_az IS 'Szakági típusa';


--
-- TOC entry 52248 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.szak_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.szak_nev IS 'Befoglaló út szakági neve kódjának sorszáma';


--
-- TOC entry 52249 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52250 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52251 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.elozo_kozut_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.elozo_kozut_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52252 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52253 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52254 (class 0 OID 0)
-- Dependencies: 429
-- Name: COLUMN t_obj_attrda.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrda.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 430 (class 1259 OID 26631614)
-- Name: t_obj_attrdb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrdb (
    kozl_id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    pont_id1 numeric(10,0),
    anyag_burk numeric(10,0),
    jell_adat1 numeric(10,0),
    jell_adat2 numeric(10,0),
    jell_adat3 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_kozl_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id2 numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrdb OWNER TO postgres;

--
-- TOC entry 52255 (class 0 OID 0)
-- Dependencies: 430
-- Name: TABLE t_obj_attrdb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrdb IS 'Belterületek közlekedési létesítményei';


--
-- TOC entry 52256 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.kozl_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.kozl_id IS 'Létesítmény azonosító sorszáma a DAT-ban';


--
-- TOC entry 52257 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.obj_fels IS 'Létesítmény objektumféleségének kódja';


--
-- TOC entry 52258 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 52259 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.szak_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.szak_nev IS 'Útszakasz esetén: a befoglaló út szakági neve kódjának sorszáma';


--
-- TOC entry 52260 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.szelv_meter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.szelv_meter IS 'Útszakasz esetén: az útszakasz kezdetének szelvényszáma a befoglaló út mentén';


--
-- TOC entry 52261 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.pont_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.pont_id1 IS 'Útszakasz esetén: az útszakasz tengelye metszi a belterületi határt (x, y)';


--
-- TOC entry 52262 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.anyag_burk; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.anyag_burk IS 'Létesítmény jellemző anyaga';


--
-- TOC entry 52263 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.jell_adat1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.jell_adat1 IS 'A létesítmény jellemzői (pl. teherbírása, áteresztőképessége, befogadóképessége) kódjának sorszáma';


--
-- TOC entry 52264 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.jell_adat2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.jell_adat2 IS 'A létesítmény jellemzői (pl. teherbírása, áteresztőképessége, befogadóképessége) kódjának sorszáma';


--
-- TOC entry 52265 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.jell_adat3; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.jell_adat3 IS 'A létesítmény jellemzői (pl. teherbírása, áteresztőképessége, befogadóképessége) kódjának sorszáma';


--
-- TOC entry 52266 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52267 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52268 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.elozo_kozl_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.elozo_kozl_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52269 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52270 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52271 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52272 (class 0 OID 0)
-- Dependencies: 430
-- Name: COLUMN t_obj_attrdb.pont_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdb.pont_id2 IS 'Geokódot jelölő pont azonosítója (útszakasz kezdete, nem útszakasz vonatkozási pontja)';


--
-- TOC entry 431 (class 1259 OID 26631617)
-- Name: t_obj_attrdc; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrdc (
    kozl_id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    anyag_burk numeric(10,0),
    jell_adat1 numeric(10,0),
    jell_adat2 numeric(10,0),
    jell_adat3 numeric(10,0),
    pont_id1 numeric(10,0),
    pont_id2 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_kozl_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id3 numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrdc OWNER TO postgres;

--
-- TOC entry 52273 (class 0 OID 0)
-- Dependencies: 431
-- Name: TABLE t_obj_attrdc; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrdc IS 'Külterületek közlekedési létesítményei';


--
-- TOC entry 52274 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.kozl_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.kozl_id IS 'Létesítmény azonosító sorszáma a DAT-ban';


--
-- TOC entry 52275 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.obj_fels IS 'Létesítmény objektumféleségének kódja';


--
-- TOC entry 52276 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 52277 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.szak_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.szak_nev IS 'Befoglaló út szakági neve kódjának sorszáma';


--
-- TOC entry 52278 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.szelv_meter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.szelv_meter IS 'Az útszakasz kezdetére vagy a nem útszakasz létesítmény vonatkozási pontjára érvényes szelvényszám a befoglaló út mentén';


--
-- TOC entry 52279 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.anyag_burk; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.anyag_burk IS 'Létesítmény jellemző anyaga';


--
-- TOC entry 52280 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.jell_adat1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.jell_adat1 IS 'A létesítmény jellemzői (pl. teherbírása, áteresztőképessége, befogadóképessége) kódjának sorszáma';


--
-- TOC entry 52281 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.jell_adat2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.jell_adat2 IS 'A létesítmény jellemzői (pl. teherbírása, áteresztőképessége, befogadóképessége) kódjának sorszáma';


--
-- TOC entry 52282 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.jell_adat3; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.jell_adat3 IS 'A létesítmény jellemzői (pl. teherbírása, áteresztőképessége, befogadóképessége) kódjának sorszáma';


--
-- TOC entry 52283 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.pont_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.pont_id1 IS 'Az útszakasz tengelye metszi a belterületi határt (x, y)';


--
-- TOC entry 52284 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.pont_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.pont_id2 IS 'a településhatárt    (x, y)';


--
-- TOC entry 52285 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.ceg_id1 IS 'Tulajdonos szervezet név- és címadatai';


--
-- TOC entry 52286 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.ceg_id2 IS 'Vagyonkezelő szervezet név- és címadatai';


--
-- TOC entry 52287 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.elozo_kozl_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.elozo_kozl_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52288 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52289 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52290 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52291 (class 0 OID 0)
-- Dependencies: 431
-- Name: COLUMN t_obj_attrdc.pont_id3; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdc.pont_id3 IS 'A geokódot kijelölő pont azonosítója (útszakasz kezdete, nem útszakasz vonatkozási pontja)';


--
-- TOC entry 432 (class 1259 OID 26631620)
-- Name: t_obj_attrdd; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrdd (
    vasut_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    kiterj numeric(4,1),
    pont_id1 numeric(10,0),
    pont_id2 numeric(10,0),
    kereszt numeric(1,0),
    obj_az numeric(10,0),
    obj_fels1 character varying(10),
    szint_dif numeric(4,1),
    pont_id3 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_vasut_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id4 numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrdd OWNER TO postgres;

--
-- TOC entry 52292 (class 0 OID 0)
-- Dependencies: 432
-- Name: TABLE t_obj_attrdd; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrdd IS 'Vasutak és más kötöttpályás közlekedési létesítmények';


--
-- TOC entry 52293 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.vasut_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.vasut_id IS 'Pályaszakasz vagy állomás azonosító sorszáma a DAT-ban';


--
-- TOC entry 52294 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.obj_fels IS 'Pályaszakasz vagy állomás objektumféleségének kódja';


--
-- TOC entry 52295 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.obj_kiterj IS 'Az objektum kiterjedése. 2-vonal, 3-felület';


--
-- TOC entry 52296 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52297 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.szak_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.szak_nev IS 'Befoglaló kötöttpályás közlekedési létesítmény szakági neve kódjának sorszáma';


--
-- TOC entry 52298 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.szelv_meter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.szelv_meter IS 'A pályaszakasz kezdetének vagy az állomás vonatkozási pontjának szelvényszáma a befoglaló közlekedési létesítmény mentén';


--
-- TOC entry 52299 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.kiterj IS 'A pályaszakasz kezdetének magassága (+) vagy mélysége (–) a terep tengelyvonalbeli felszínéhez képest';


--
-- TOC entry 52300 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.pont_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.pont_id1 IS 'A pályaszakasz tengelye metszi a belterületi határt (x, y)';


--
-- TOC entry 52301 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.pont_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.pont_id2 IS 'a településhatárt  (x, y)';


--
-- TOC entry 52302 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.kereszt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.kereszt IS 'Pályaszakasz esetén: keresztez-e vonalas közlekedési létesítményt vagy nem';


--
-- TOC entry 52303 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.obj_az; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.obj_az IS 'Ha keresztez, akkor a keresztezett objektum azonosító sorszáma a DAT-ban';


--
-- TOC entry 52304 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.obj_fels1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.obj_fels1 IS 'Ha keresztez, akkor a keresztezett objektum objektumféleségének kódja';


--
-- TOC entry 52305 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.szint_dif; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.szint_dif IS 'Ha keresztez, akkor a kereszteződés szintkülönbsége tengelyben (ha a kereszteződés egyszintű, akkor 0, ha a keresztezett objektum felül van, akkor +, ha alul, akkor –)';


--
-- TOC entry 52306 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.pont_id3; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.pont_id3 IS 'Ha keresztez, akkor a kereszteződés koordinátái tengelyben';


--
-- TOC entry 52307 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52308 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52309 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.elozo_vasut_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.elozo_vasut_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52310 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52311 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52312 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52313 (class 0 OID 0)
-- Dependencies: 432
-- Name: COLUMN t_obj_attrdd.pont_id4; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdd.pont_id4 IS 'A geokódot kijelölő pont azonosítója (pályaszakasz kezdete vagy állomás vonatkozási pontja)';


--
-- TOC entry 433 (class 1259 OID 26631623)
-- Name: t_obj_attrde; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrde (
    repter_id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    szak_nev1 numeric(10,0),
    repter_tip numeric(10,0),
    repter_oszt numeric(10,0),
    szak_nev2 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_repter_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrde OWNER TO postgres;

--
-- TOC entry 52314 (class 0 OID 0)
-- Dependencies: 433
-- Name: TABLE t_obj_attrde; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrde IS 'Légiforgalmi létesítmények';


--
-- TOC entry 52315 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.repter_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.repter_id IS 'Légiforgalmi létesítmény azonosító sorszáma a DAT-ban';


--
-- TOC entry 52316 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.obj_fels IS 'Légiforgalmi létesítmény objektumféleségének kódja';


--
-- TOC entry 52317 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.felulet_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.felulet_id IS 'Az objektum geometriáját leíró felület azonosítója';


--
-- TOC entry 52318 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.szak_nev1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.szak_nev1 IS 'Ha az objektum repülőtér, akkor annak szakági neve ';


--
-- TOC entry 52319 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.repter_tip; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.repter_tip IS 'Ha az objektum repülőtér, akkor annak típusa (kód)';


--
-- TOC entry 52320 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.repter_oszt; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.repter_oszt IS 'Ha az objektum repülőtér, akkor annak osztálybasorolása (kód)';


--
-- TOC entry 52321 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.szak_nev2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.szak_nev2 IS 'Ha az objektum a repülőtér valamely létesítménye, akkor a befoglaló repülőtér szakági neve kódjának sorszáma';


--
-- TOC entry 52322 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52323 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52324 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.elozo_repter_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.elozo_repter_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52325 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52326 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.jelkulcs IS 'Megjelenítéséhez a jelkulcs kódja';


--
-- TOC entry 52327 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52328 (class 0 OID 0)
-- Dependencies: 433
-- Name: COLUMN t_obj_attrde.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrde.pont_id IS 'A létesítmény vonatkozási pontjára érvényes geokódot kijelölő pont azonosítója';


--
-- TOC entry 434 (class 1259 OID 26631626)
-- Name: t_obj_attrdf; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrdf (
    mutargy_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    athid_szerk numeric(10,0),
    anyag_burk numeric(10,0),
    teherbir numeric(6,1),
    athid_allapot numeric(10,0),
    athid_akad numeric(10,0),
    szeles numeric(5,1),
    magas numeric(4,1),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_mutargy_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrdf OWNER TO postgres;

--
-- TOC entry 52329 (class 0 OID 0)
-- Dependencies: 434
-- Name: TABLE t_obj_attrdf; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrdf IS 'Közlekedés műtárgyai (I.)';


--
-- TOC entry 52330 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.mutargy_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.mutargy_id IS 'Műtárgy azonosító sorszáma a DAT-ban';


--
-- TOC entry 52331 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.obj_fels IS 'Műtárgy objektumféleségének kódja';


--
-- TOC entry 52332 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.obj_kiterj IS 'Az objektum kiterjedése. 2-vonal, 3-felület';


--
-- TOC entry 52333 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52334 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.szak_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.szak_nev IS 'Befoglaló út vagy pálya szakági neve kódjának sorszáma';


--
-- TOC entry 52335 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.szelv_meter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.szelv_meter IS 'A műtárgy szelvényszáma a befoglaló út vagy pálya mentén';


--
-- TOC entry 52336 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.athid_szerk; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.athid_szerk IS 'Műtárgy szerkezeti rendszere';


--
-- TOC entry 52337 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.anyag_burk; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.anyag_burk IS 'Műtárgy anyaga';


--
-- TOC entry 52338 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.teherbir; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.teherbir IS 'Műtárgy teherbírása';


--
-- TOC entry 52339 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.athid_allapot; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.athid_allapot IS 'Műtárgy komplex állapotkódja';


--
-- TOC entry 52340 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.athid_akad; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.athid_akad IS 'Áthidalt akadály vagy az átsegített forgalom típusa';


--
-- TOC entry 52341 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.szeles; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.szeles IS 'Szabad nyílás szélessége';


--
-- TOC entry 52342 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.magas; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.magas IS 'Szabad nyílás magassága';


--
-- TOC entry 52343 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52344 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52345 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.elozo_mutargy_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.elozo_mutargy_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52346 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52347 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52348 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52349 (class 0 OID 0)
-- Dependencies: 434
-- Name: COLUMN t_obj_attrdf.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdf.pont_id IS 'A műtárgy vonatkozási pontjára vonatkozó geokódot kijelölő pont (pl. tengelyvonalak kereszteződése) azonosítója';


--
-- TOC entry 435 (class 1259 OID 26631629)
-- Name: t_obj_attrdg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrdg (
    mutargy_id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    kiterj numeric(4,1),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_mutargy_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrdg OWNER TO postgres;

--
-- TOC entry 52350 (class 0 OID 0)
-- Dependencies: 435
-- Name: TABLE t_obj_attrdg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrdg IS 'Közlekedés műtárgyai (II.)';


--
-- TOC entry 52351 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.mutargy_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.mutargy_id IS 'Műtárgy azonosító sorszáma a DAT-ban';


--
-- TOC entry 52352 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.obj_fels; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.obj_fels IS 'Műtárgy objektumféleségének kódja';


--
-- TOC entry 52353 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.obj_kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.obj_kiterj IS 'Az objektum kiterjedése. 1-pont, 2-vonal, 3-felület';


--
-- TOC entry 52354 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.geo_ae_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.geo_ae_id IS 'Az objektum geometriáját leíró geometriai alapelem azonosító sorszáma (amely az obj_fels alapján a T_GEOM-ban kiválasztott geo_ae_tabla nevű táblázatból származik)';


--
-- TOC entry 52355 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.szak_nev; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.szak_nev IS 'Befoglaló út vagy pálya szakági neve kódjának sorszáma';


--
-- TOC entry 52356 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.szelv_meter; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.szelv_meter IS 'A pontszerű műtárgynak vagy a nem pontszerű műtárgy szakaszkezdetének szelvényszáma a befoglaló út vagy pálya mentén';


--
-- TOC entry 52357 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.kiterj; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.kiterj IS 'A műtárgy függőleges kiterjedése';


--
-- TOC entry 52358 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.ceg_id1; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.ceg_id1 IS 'Tulajdonos szervezet, név- és címadatai';


--
-- TOC entry 52359 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.ceg_id2; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.ceg_id2 IS 'Vagyonkezelő szervezet, név- és címadatai';


--
-- TOC entry 52360 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.elozo_mutargy_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.elozo_mutargy_id IS 'Az objektum legutóbbi érvényességű azonosítója';


--
-- TOC entry 52361 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.megsz_datum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.megsz_datum IS 'Az adatrekord érvényessége megszűnésének dátuma';


--
-- TOC entry 52362 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.jelkulcs; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.jelkulcs IS 'Megjelenítéshez a jelkulcs kódja';


--
-- TOC entry 52363 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.munkater_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.munkater_id IS 'A vonatkozó felmérési munkaterület azonosítója';


--
-- TOC entry 52364 (class 0 OID 0)
-- Dependencies: 435
-- Name: COLUMN t_obj_attrdg.pont_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_obj_attrdg.pont_id IS 'A műtárgy szakaszkezdetére vagy vonatkozási pontjára vonatkozó geokódot kijelölő pont azonosítója';


--
-- TOC entry 436 (class 1259 OID 26631632)
-- Name: t_obj_attrea; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrea (
    id numeric(10,0),
    obj_fels character varying(10),
    vonal_id numeric(10,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    kiterj numeric(4,1),
    ved_sav numeric(10,0),
    korlat numeric(10,0),
    jell_adat1 numeric(10,0),
    jell_adat2 numeric(10,0),
    jell_adat3 numeric(10,0),
    pont_id1 numeric(10,0),
    pont_id2 numeric(10,0),
    kereszt numeric(1,0),
    obj_az numeric(10,0),
    obj_fels1 character varying(10),
    szint_dif numeric(4,1),
    pont_id3 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrea OWNER TO postgres;

--
-- TOC entry 52365 (class 0 OID 0)
-- Dependencies: 436
-- Name: TABLE t_obj_attrea; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrea IS 'Távvezetékek, függőpályák tengelyvonalai';


--
-- TOC entry 437 (class 1259 OID 26631635)
-- Name: t_obj_attreb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attreb (
    id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    szak_nev numeric(10,0),
    szelv_meter numeric(8,0),
    kiterj numeric(4,1),
    ved_sav numeric(10,0),
    korlat numeric(10,0),
    jell_adat numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attreb OWNER TO postgres;

--
-- TOC entry 52366 (class 0 OID 0)
-- Dependencies: 437
-- Name: TABLE t_obj_attreb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attreb IS 'Távvezetékek, függőpályák műtárgyai';


--
-- TOC entry 438 (class 1259 OID 26631638)
-- Name: t_obj_attrfa; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrfa (
    id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    vobj_fo_al numeric(10,0),
    szelv_meter numeric(8,0),
    jell_adat1 numeric(10,0),
    jell_adat2 numeric(10,0),
    jell_adat3 numeric(10,0),
    pont_id1 numeric(10,0),
    pont_id2 numeric(10,0),
    kereszt numeric(1,0),
    obj_az numeric(10,0),
    obj_fels1 character varying(10),
    szint_dif numeric(4,1),
    pont_id3 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrfa OWNER TO postgres;

--
-- TOC entry 52367 (class 0 OID 0)
-- Dependencies: 438
-- Name: TABLE t_obj_attrfa; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrfa IS 'Folyóvizek és állóvizek';


--
-- TOC entry 439 (class 1259 OID 26631641)
-- Name: t_obj_attrfb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrfb (
    id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    vobj_fo_al numeric(10,0),
    szelv_meter numeric(8,0),
    kiterj numeric(4,1),
    ved_sav numeric(10,0),
    korlat numeric(10,0),
    jell_adat1 numeric(10,0),
    jell_adat2 numeric(10,0),
    jell_adat3 numeric(10,0),
    pont_id1 numeric(10,0),
    pont_id2 numeric(10,0),
    kereszt numeric(1,0),
    obj_az numeric(10,0),
    obj_fels1 character varying(10),
    szint_dif numeric(4,1),
    pont_id3 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrfb OWNER TO postgres;

--
-- TOC entry 52368 (class 0 OID 0)
-- Dependencies: 439
-- Name: TABLE t_obj_attrfb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrfb IS 'Vízi közművek';


--
-- TOC entry 440 (class 1259 OID 26631644)
-- Name: t_obj_attrfc; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrfc (
    id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    vobj_fo_al numeric(10,0),
    szelv_meter numeric(8,0),
    kiterj numeric(4,1),
    korlat numeric(10,0),
    jell_adat1 numeric(10,0),
    jell_adat2 numeric(10,0),
    jell_adat3 numeric(10,0),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrfc OWNER TO postgres;

--
-- TOC entry 52369 (class 0 OID 0)
-- Dependencies: 440
-- Name: TABLE t_obj_attrfc; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrfc IS 'Vízügyi műtárgyak';


--
-- TOC entry 441 (class 1259 OID 26631647)
-- Name: t_obj_attrga; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrga (
    id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0)
);


ALTER TABLE datr_sablon.t_obj_attrga OWNER TO postgres;

--
-- TOC entry 52370 (class 0 OID 0)
-- Dependencies: 441
-- Name: TABLE t_obj_attrga; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrga IS 'Szintvonalak';


--
-- TOC entry 442 (class 1259 OID 26631650)
-- Name: t_obj_attrgb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrgb (
    id numeric(10,0),
    obj_fels character varying(10),
    obj_kiterj numeric(10,0),
    geo_ae_id numeric(8,0),
    pont_id1 numeric(10,0),
    pont_id2 numeric(10,0),
    lok_kiterj numeric(4,2),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    jelkulcs numeric(3,0),
    munkater_id numeric(6,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrgb OWNER TO postgres;

--
-- TOC entry 52371 (class 0 OID 0)
-- Dependencies: 442
-- Name: TABLE t_obj_attrgb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrgb IS 'Domborzati alakzatok';


--
-- TOC entry 443 (class 1259 OID 26631653)
-- Name: t_obj_attrha; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrha (
    id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    felm_tan character varying(150),
    mu_terv character varying(150),
    mu_leir character varying(150),
    torzskonyv character varying(150),
    forras character varying(150),
    munkareszek character varying(150),
    kezd_datum numeric(8,0),
    bef_datum numeric(8,0),
    felm_datum numeric(8,0),
    hitel_datum numeric(8,0),
    bevit_datum numeric(8,0),
    adatgy1 character varying(10),
    adatgy2 character varying(10),
    adatgy3 character varying(10),
    adatgy4 character varying(10),
    ceg_id1 numeric(10,0),
    szemely_id1 numeric(10,0),
    munkater_ny_m character varying(20),
    ceg_id2 numeric(10,0),
    szemely_id2 numeric(10,0),
    munkater_ny_f character varying(20),
    ceg_id3 numeric(10,0),
    szemely_id3 numeric(10,0),
    munkater_ny_h character varying(20),
    munkater_id_knt character varying(20),
    szemely_id4 numeric(10,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrha OWNER TO postgres;

--
-- TOC entry 52372 (class 0 OID 0)
-- Dependencies: 443
-- Name: TABLE t_obj_attrha; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrha IS 'Felmérési munkaterületek';


--
-- TOC entry 444 (class 1259 OID 26631656)
-- Name: t_obj_attrhb; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrhb (
    id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    nyt_nev character varying(30),
    ceg_id1 numeric(10,0),
    szemely_id2 numeric(10,0),
    kezd_datum numeric(8,0),
    bef_datum numeric(8,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrhb OWNER TO postgres;

--
-- TOC entry 52373 (class 0 OID 0)
-- Dependencies: 444
-- Name: TABLE t_obj_attrhb; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrhb IS 'DAT adatbázis kezelési egységek';


--
-- TOC entry 445 (class 1259 OID 26631659)
-- Name: t_obj_attrhc; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_obj_attrhc (
    id numeric(10,0),
    obj_fels character varying(10),
    felulet_id numeric(8,0),
    ter_nev character varying(30),
    ceg_id1 numeric(10,0),
    ceg_id2 numeric(10,0),
    kezd_datum numeric(8,0),
    szemely_id3 numeric(10,0),
    elozo_id numeric(10,0),
    megsz_datum numeric(8,0),
    pont_id numeric(10,0)
);


ALTER TABLE datr_sablon.t_obj_attrhc OWNER TO postgres;

--
-- TOC entry 52374 (class 0 OID 0)
-- Dependencies: 445
-- Name: TABLE t_obj_attrhc; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_obj_attrhc IS 'Térség jellegű területek';


--
-- TOC entry 446 (class 1259 OID 26631662)
-- Name: t_orpont_gy; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_orpont_gy (
    tabla_nev character varying(12),
    alappont_id numeric(10,0),
    orpont_szam character varying(20),
    mag_alland numeric(10,0),
    magassag numeric(8,3),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_orpont_gy OWNER TO postgres;

--
-- TOC entry 52375 (class 0 OID 0)
-- Dependencies: 446
-- Name: TABLE t_orpont_gy; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_orpont_gy IS 'Magassági alappontok őrpontjainak gyűjtőtáblázata';


--
-- TOC entry 447 (class 1259 OID 26631665)
-- Name: t_osadatal12; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_osadatal12 (
    osadat12_id numeric(6,0) NOT NULL,
    munkater_id numeric(6,0),
    tulaj_id numeric(8,0),
    ostulaj_let character varying(50),
    kapcsolat_id numeric(8,0),
    oscel character varying(150),
    ceg_id_felmer numeric(6,0),
    osdatum numeric(8,0),
    vetulet numeric(2,0),
    vonatk_r numeric(2,0),
    osadatgyujt character varying(500),
    oshitel character varying(150),
    osterulet character varying(250),
    ceg_id_alakit numeric(6,0),
    alakitdatum numeric(6,0),
    alakit1 character varying(150),
    alakit2 character varying(500),
    alakit3 character varying(500),
    alakit4 character varying(500),
    alakit5 character varying(250),
    minosites character varying(250)
);


ALTER TABLE datr_sablon.t_osadatal12 OWNER TO postgres;

--
-- TOC entry 52376 (class 0 OID 0)
-- Dependencies: 447
-- Name: TABLE t_osadatal12; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_osadatal12 IS 'Ősadatállomány minőségadatainak táblázata';


--
-- TOC entry 448 (class 1259 OID 26631671)
-- Name: t_osszekot_iv; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_osszekot_iv (
    osszekot_id numeric(8,0),
    center_x numeric(9,2),
    center_y numeric(9,2),
    sugar numeric(8,2)
);


ALTER TABLE datr_sablon.t_osszekot_iv OWNER TO postgres;

--
-- TOC entry 52377 (class 0 OID 0)
-- Dependencies: 448
-- Name: TABLE t_osszekot_iv; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_osszekot_iv IS 'Pontok összekötése adatainak táblázata';


--
-- TOC entry 52378 (class 0 OID 0)
-- Dependencies: 448
-- Name: COLUMN t_osszekot_iv.osszekot_id; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_osszekot_iv.osszekot_id IS 'Az összekötés-előfordulás azonosító sorszáma';


--
-- TOC entry 52379 (class 0 OID 0)
-- Dependencies: 448
-- Name: COLUMN t_osszekot_iv.center_x; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_osszekot_iv.center_x IS 'Az ív középpontjának EOV x koordinátája';


--
-- TOC entry 52380 (class 0 OID 0)
-- Dependencies: 448
-- Name: COLUMN t_osszekot_iv.center_y; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_osszekot_iv.center_y IS 'Az ív középpontjának EOV y koordinátája';


--
-- TOC entry 52381 (class 0 OID 0)
-- Dependencies: 448
-- Name: COLUMN t_osszekot_iv.sugar; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_osszekot_iv.sugar IS 'Az ív sugara';


--
-- TOC entry 449 (class 1259 OID 26631674)
-- Name: t_qgeometria; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_qgeometria (
    qgeometria_id numeric(6,0) NOT NULL,
    munkater_id numeric(6,0),
    smegeng1 numeric(5,0),
    smegeng2 numeric(4,0),
    smegeng3 numeric(4,0),
    smegeng4 numeric(4,0),
    smegeng5 numeric(4,0),
    smegeng6 numeric(4,0),
    smegeng7 numeric(4,0),
    smegeng8 numeric(4,0),
    smegeng9 numeric(4,0),
    smegeng10 numeric(4,0),
    smegeng11 numeric(4,0),
    smegeng12 numeric(4,0),
    smegeng13 numeric(4,0),
    smegeng14 numeric(4,0),
    smegeng15 numeric(4,0),
    smegeng16 numeric(4,0),
    smegeng17 numeric(4,0),
    smegeng18 numeric(4,0),
    smegeng19 numeric(4,0),
    smegeng20 numeric(4,0),
    smegeng21 numeric(4,0),
    smegeng22 numeric(3,0),
    smegeng23 numeric(3,0),
    smegeng24 numeric(4,0),
    smegeng25 numeric(5,0),
    smegeng26 numeric(5,0),
    smegeng27 numeric(5,0),
    smegeng28 numeric(4,0),
    smegeng29 numeric(4,0),
    smegeng30 numeric(4,0),
    smegeng31 numeric(4,0),
    smegeng32 numeric(4,0),
    smegeng33 numeric(4,0),
    smegeng34 numeric(4,0),
    smegeng35 numeric(4,0),
    smegeng36 numeric(4,0),
    smegeng37 numeric(3,0),
    smegeng38 numeric(4,0),
    tenylg1 numeric(5,0),
    tenylg2 numeric(4,0),
    tenylg3 numeric(4,0),
    tenylg4 numeric(4,0),
    tenylg5 numeric(4,0),
    tenylg6 numeric(4,0),
    tenylg7 numeric(4,0),
    tenylg8 numeric(4,0),
    tenylg9 numeric(4,0),
    tenylg10 numeric(4,0),
    tenylg11 numeric(4,0),
    tenylg12 numeric(4,0),
    tenylg13 numeric(4,0),
    tenylg14 numeric(4,0),
    tenylg15 numeric(4,0),
    tenylg16 numeric(4,0),
    tenylg17 numeric(4,0),
    tenylg18 numeric(4,0),
    tenylg19 numeric(4,0),
    tenylg20 numeric(4,0),
    tenylg21 numeric(4,0),
    tenylg22 numeric(3,0),
    tenylg23 numeric(3,0),
    tenylg24 numeric(4,0),
    tenylg25 numeric(5,0),
    tenylg26 numeric(5,0),
    tenylg27 numeric(5,0),
    tenylg28 numeric(4,0),
    tenylg29 numeric(4,0),
    tenylg30 numeric(4,0),
    tenylg31 numeric(4,0),
    tenylg32 numeric(4,0),
    tenylg33 numeric(4,0),
    tenylg34 numeric(4,0),
    tenylg35 numeric(4,0),
    tenylg36 numeric(4,0),
    tenylg37 numeric(3,0),
    tenylg38 numeric(3,0),
    eltermax1 numeric(5,0),
    eltermax2 numeric(4,0),
    eltermax3 numeric(4,0),
    eltermax4 numeric(4,0),
    eltermax5 numeric(4,0),
    eltermax6 numeric(4,0),
    eltermax7 numeric(4,0),
    eltermax8 numeric(4,0),
    eltermax9 numeric(4,0),
    eltermax10 numeric(4,0),
    eltermax11 numeric(4,0),
    eltermax12 numeric(4,0),
    eltermax13 numeric(4,0),
    eltermax14 numeric(4,0),
    eltermax15 numeric(4,0),
    eltermax16 numeric(4,0),
    eltermax17 numeric(4,0),
    eltermax18 numeric(4,0),
    eltermax19 numeric(4,0),
    eltermax20 numeric(4,0),
    eltermax21 numeric(4,0),
    eltermax22 numeric(3,0),
    eltermax23 numeric(3,0),
    eltermax24 numeric(4,0),
    eltermax25 numeric(5,0),
    eltermax26 numeric(5,0),
    eltermax27 numeric(5,0),
    eltermax28 numeric(4,0),
    eltermax29 numeric(4,0),
    eltermax30 numeric(4,0),
    eltermax31 numeric(4,0),
    eltermax32 numeric(4,0),
    eltermax33 numeric(4,0),
    eltermax34 numeric(4,0),
    eltermax35 numeric(4,0),
    eltermax36 numeric(4,0),
    eltermax37 numeric(3,0),
    eltermax38 numeric(3,0),
    vminmax1 numeric(5,0),
    vminmax2 numeric(4,0),
    vminmax3 numeric(4,0),
    vminmax4 numeric(4,0),
    vminmax5 numeric(4,0),
    vminmax6 numeric(4,0),
    vminmax7 numeric(4,0),
    vminmax8 numeric(4,0),
    vminmax9 numeric(4,0),
    vminmax10 numeric(4,0),
    vminmax11 numeric(5,0),
    vminmax12 numeric(4,0),
    vminmax13 numeric(4,0),
    vminmax14 numeric(4,0),
    vminmax15 numeric(4,0),
    vminmax16 numeric(4,0),
    vminmax17 numeric(4,0),
    vminmax18 numeric(4,0),
    vminmax19 numeric(4,0),
    vminmax20 numeric(5,0),
    vminmax21 numeric(5,0),
    vminmax22 numeric(3,0),
    vminmax23 numeric(3,0),
    vminmax24 numeric(4,0),
    vminmax25 numeric(5,0),
    vminmax26 numeric(5,0),
    vminmax27 numeric(5,0),
    vminmax28 numeric(4,0),
    vminmax29 numeric(4,0),
    vminmax30 numeric(5,0),
    vminmax31 numeric(5,0),
    vminmax32 numeric(4,0),
    vminmax33 numeric(4,0),
    vminmax34 numeric(4,0),
    vminmax35 numeric(4,0),
    vminmax36 numeric(4,0),
    vminmax37 numeric(3,0),
    vminmax38 numeric(3,0)
);


ALTER TABLE datr_sablon.t_qgeometria OWNER TO postgres;

--
-- TOC entry 52382 (class 0 OID 0)
-- Dependencies: 449
-- Name: TABLE t_qgeometria; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_qgeometria IS 'Geometriai adatok minőségének táblázata';


--
-- TOC entry 450 (class 1259 OID 26631677)
-- Name: t_szemely; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_szemely (
    szemely_id numeric(10,0),
    eredeti_id numeric(10,0),
    vez_nev character varying(25),
    uto_nev1 character varying(15),
    uto_nev2 character varying(15),
    lvez_nev character varying(25),
    luto_nev1 character varying(15),
    luto_nev2 character varying(15),
    dr_s character varying(2),
    dr_sz character varying(2),
    szem_szam numeric(12,0),
    avez_nev character varying(25),
    auto_nev1 character varying(15),
    auto_nev2 character varying(15),
    telefon numeric(15,0),
    fax numeric(15,0),
    e_mail character varying(30),
    cim_id numeric(10,0),
    szemely_szerep numeric(10,0),
    elozo_id numeric(10,0),
    erv_datum numeric(8,0),
    megsz_datum numeric(8,0)
);


ALTER TABLE datr_sablon.t_szemely OWNER TO postgres;

--
-- TOC entry 52383 (class 0 OID 0)
-- Dependencies: 450
-- Name: TABLE t_szemely; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_szemely IS 'Személyek adatainak táblázata';


--
-- TOC entry 451 (class 1259 OID 26631680)
-- Name: t_szimbolum; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_szimbolum (
    szimbolum_id numeric(10,0),
    jelkulcs numeric(3,0),
    pont_id_szimb numeric(8,0) NOT NULL,
    irany_szimb numeric(5,0),
    tabla_nev character varying(12),
    sor_id numeric(10,0),
    szulo_objektum_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_szimbolum OWNER TO postgres;

--
-- TOC entry 52384 (class 0 OID 0)
-- Dependencies: 451
-- Name: TABLE t_szimbolum; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_szimbolum IS 'Állami alapadatokhoz és alapadatokhoz szükséges táblázat';


--
-- TOC entry 452 (class 1259 OID 26631683)
-- Name: t_teljesseg; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_teljesseg (
    teljesseg_id numeric(6,0) NOT NULL,
    sub_id numeric(2,0),
    munkater_id numeric(6,0),
    obj_oszt character varying(1),
    obj_telj numeric(5,0),
    obj_fels_h character varying(185),
    obj_fels_t character varying(50),
    attr_telj numeric(5,0),
    attr_fels_h character varying(134),
    attr_fels_t character varying(50),
    felm_teljesseg character varying(250)
);


ALTER TABLE datr_sablon.t_teljesseg OWNER TO postgres;

--
-- TOC entry 52385 (class 0 OID 0)
-- Dependencies: 452
-- Name: TABLE t_teljesseg; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_teljesseg IS 'Adatok teljességét leíró táblázat
Ordas.dat beolvasásakor az "obj_fels_h" mezőt "185" karakteresre kellett állítani!
';


--
-- TOC entry 52386 (class 0 OID 0)
-- Dependencies: 452
-- Name: COLUMN t_teljesseg.obj_fels_h; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON COLUMN datr_sablon.t_teljesseg.obj_fels_h IS 'Ordas.dat miatt 99-ről növelve 185-re';


--
-- TOC entry 453 (class 1259 OID 26631689)
-- Name: t_veg_cspont; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_veg_cspont (
    veg_cspont_id numeric(8,0) NOT NULL,
    pont_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_veg_cspont OWNER TO postgres;

--
-- TOC entry 52387 (class 0 OID 0)
-- Dependencies: 453
-- Name: TABLE t_veg_cspont; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_veg_cspont IS 'Végcsomópontok táblázata';


--
-- TOC entry 454 (class 1259 OID 26631692)
-- Name: t_veg_cspont_el; Type: TABLE; Schema: datr_sablon; Owner: postgres
--

CREATE TABLE datr_sablon.t_veg_cspont_el (
    veg_cspont_id1 numeric(8,0),
    veg_cspont_id2 numeric(8,0),
    el_id numeric(8,0)
);


ALTER TABLE datr_sablon.t_veg_cspont_el OWNER TO postgres;

--
-- TOC entry 52388 (class 0 OID 0)
-- Dependencies: 454
-- Name: TABLE t_veg_cspont_el; Type: COMMENT; Schema: datr_sablon; Owner: postgres
--

COMMENT ON TABLE datr_sablon.t_veg_cspont_el IS 'Végcsomópontok élekhez rendelésének táblázata';


--
-- TOC entry 51581 (class 0 OID 26631481)
-- Dependencies: 387
-- Data for Name: t_ahaszn_reg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51582 (class 0 OID 26631484)
-- Dependencies: 388
-- Data for Name: t_attrbizn; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51583 (class 0 OID 26631487)
-- Dependencies: 389
-- Data for Name: t_attrelter; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51584 (class 0 OID 26631490)
-- Dependencies: 390
-- Data for Name: t_ceg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51569 (class 0 OID 26631357)
-- Dependencies: 360
-- Data for Name: t_cim; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51585 (class 0 OID 26631493)
-- Dependencies: 391
-- Data for Name: t_cim_kulfold; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51586 (class 0 OID 26631496)
-- Dependencies: 392
-- Data for Name: t_el; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51587 (class 0 OID 26631499)
-- Dependencies: 393
-- Data for Name: t_eredet; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51567 (class 0 OID 26631341)
-- Dependencies: 357
-- Data for Name: t_felirat; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51649 (class 0 OID 188629760)
-- Dependencies: 609
-- Data for Name: t_felirat_jelleg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--

INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (0, '-', 1);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (1, 'Vízszintes felső és IV-V. rendű alappont', 8);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (2, 'Magassági fő; I-IV. rendű alappont', 3);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (3, 'Gravimetriai alappont', 8);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (4, 'Országnév', 25);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (5, 'Megye neve', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (6, 'Településnév', 25);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (7, 'Fekvés neve', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (8, 'Kerület neve', 23);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (9, 'Tömbszám', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (11, 'Helyrajzi szám (jogerős)', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (13, 'Alrészlet betűjele', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (14, 'Alrészlet művelési ága', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (15, 'Minőségi osztály', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (16, 'Szabvány alatti alrészlet művelési ág', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (17, 'Szabvány alatti minőségi osztály', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (26, 'Záradékolás iktatószáma', 8);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (27, 'Természetvédelmi terület neve', 12);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (28, 'Bányaterület neve', 12);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (29, 'Vizmű, forrás, fürdő védőterület neve', 12);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (31, 'Gazdasági- és melléképület > 12m2', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (32, 'Középület, közintézmény', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (33, 'Templom, kápolna, mauzóleum, imaház', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (34, 'Üzemi épület', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (35, 'Házszám', 5);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (36, 'Épület tartozék:"terasz", "rámpa"', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (37, 'Vetített sík', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (38, 'Toronyszerű építmények, emlékművek nevei', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (40, 'Támfal', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (41, 'Töltés', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (42, 'Műemlékrom', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (43, 'Út, utca, tér, közterület neve', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (44, 'Lépcső közterületen', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (45, 'Burkolat megnevezése', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (46, 'I. r. utak száma + "közl út"', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (47, 'I. r. út: "padka", "árok", "töltés"', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (48, 'II. r. utak száma + "közl út"', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (49, 'II. r. út: "padka", "árok", "töltés"', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (50, 'Mellékutak: "közl. út"', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (51, 'Egyéb közl. utak: "út", "kerékpárút"', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (52, 'Vasút felirat', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (53, 'Villamos/HÉV felirat', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (54, 'Kisnyomtávú "iparvasút", "erdei vasút"', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (55, '"sikló", "fogaskerekű" felirat', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (56, 'Híd neve', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (57, 'felüljáró (gyalogos, közúti) "közl. út"', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (58, 'Folyó, tó neve', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (59, 'Vízműtárgy:"zsilip", "móló", "duzzasztó (vb.)"', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (60, '"víztorony", "hidroglóbusz" felirat', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (61, '"forrás", "kút", "szökőkút" feliratok', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (63, 'drótkötélpálya "drkp."', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (64, 'Egyéb függőpálya pl.:"sífelvonó"', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (66, 'Olaj / gáztermelő kút "O" "G"', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (67, 'Távvezetékek (felszín és ~felett) "Gő" "M" "O" "G"', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (68, 'Tartály (olaj, gáz, üa.) "O" "G" "Üa."', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (69, 'Távvezetékek (felszín alatt) "O", "G", "V", stb.', 6);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (73, 'Biztonsági övezet (távvezeték)', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (74, 'Benzinkút "Üa. állomás"', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (75, '"szélmotor" "sír" "dögk." feliratok', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (76, 'OGPSH alappont', 8);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (77, 'Kéregmozgási alappont', 8);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (78, 'Teljes hrsz. a területszámításhoz', 27);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (83, 'Közterületről nyíló pince', 1);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (86, 'dűlőnév, földrajzi név', 13);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (88, 'Belterületi árok (nem alrészlet)', 1);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (89, 'Talajút, dűlőút: "út"', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (90, 'Külterületi árok (nem alrészlet)', 1);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (91, 'Alagút', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (92, 'Töredék hrsz. a kirajzoláshoz', 2);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (93, 'Vegyes funkciójú épület', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (94, 'Rendezetlen funkciójú épület', 4);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (95, 'Mintatér', 8);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (98, 'Egyéb önálló ingatlan', 1);
INSERT INTO datr_sablon.t_felirat_jelleg (kod, ertek, font_id) VALUES (105, 'Hibás érték!!!', 0);


--
-- TOC entry 51575 (class 0 OID 26631420)
-- Dependencies: 373
-- Data for Name: t_felulet; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51650 (class 0 OID 188629766)
-- Dependencies: 610
-- Data for Name: t_font; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--

INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (0, 'ismeretlen', 1, 1.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (1, 'ARIAL CE álló', 6, 1.50);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (2, 'ARIAL CE dőlt', 6, 1.50);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (3, 'ARIAL CE álló', 7, 1.75);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (4, 'ARIAL CE dőlt', 7, 1.75);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (5, 'ARIAL CE álló', 8, 2.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (6, 'ARIAL CE dőlt', 8, 2.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (7, 'ARIAL CE dőlt', 9, 2.25);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (8, 'ARIAL CE álló', 10, 2.50);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (9, 'ARIAL CE dőlt', 10, 2.50);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (10, 'ARIAL CE álló', 11, 2.75);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (11, 'ARIAL CE dőlt', 11, 2.75);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (12, 'ARIAL CE álló', 12, 3.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (13, 'ARIAL CE dőlt', 12, 3.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (14, 'ARIAL CE álló', 13, 3.25);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (15, 'ARIAL CE dőlt', 13, 3.25);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (16, 'ARIAL CE álló', 14, 3.50);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (17, 'ARIAL CE dőlt', 14, 3.50);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (18, 'ARIAL CE álló', 15, 3.75);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (19, 'ARIAL CE dőlt', 15, 3.75);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (20, 'ARIAL CE álló', 16, 4.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (21, 'ARIAL CE dőlt', 16, 4.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (22, 'ARIAL CE álló', 20, 5.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (23, 'ARIAL CE dőlt', 20, 5.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (24, 'ARIAL CE álló', 28, 7.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (25, 'ARIAL CE dőlt', 28, 7.00);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (26, 'ARIAL CE álló', 9, 2.25);
INSERT INTO datr_sablon.t_font (kod, betu_tipus, nagysag, magassag) VALUES (27, 'ARIAL CE álló', 0, 0.00);


--
-- TOC entry 51588 (class 0 OID 26631502)
-- Dependencies: 394
-- Data for Name: t_gyuru; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51573 (class 0 OID 26631394)
-- Dependencies: 367
-- Data for Name: t_hatar; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51574 (class 0 OID 26631397)
-- Dependencies: 368
-- Data for Name: t_hatarvonal; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51589 (class 0 OID 26631505)
-- Dependencies: 395
-- Data for Name: t_helyreall_gy; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51590 (class 0 OID 26631508)
-- Dependencies: 396
-- Data for Name: t_helyreall_gyio; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51591 (class 0 OID 26631511)
-- Dependencies: 397
-- Data for Name: t_helyszin_gy; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51592 (class 0 OID 26631514)
-- Dependencies: 398
-- Data for Name: t_helyszin_gyio; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51593 (class 0 OID 26631517)
-- Dependencies: 399
-- Data for Name: t_hiteles; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51594 (class 0 OID 26631523)
-- Dependencies: 400
-- Data for Name: t_iranypont_gy; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51595 (class 0 OID 26631526)
-- Dependencies: 401
-- Data for Name: t_izolalt; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51596 (class 0 OID 26631529)
-- Dependencies: 402
-- Data for Name: t_izolalt_l; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51597 (class 0 OID 26631532)
-- Dependencies: 403
-- Data for Name: t_konziszt; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51598 (class 0 OID 26631535)
-- Dependencies: 404
-- Data for Name: t_kozb_cspont; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51599 (class 0 OID 26631538)
-- Dependencies: 405
-- Data for Name: t_kozb_cspont_el; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51600 (class 0 OID 26631541)
-- Dependencies: 406
-- Data for Name: t_kozb_cspont_gy; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51570 (class 0 OID 26631360)
-- Dependencies: 361
-- Data for Name: t_kozter_jell; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51571 (class 0 OID 26631363)
-- Dependencies: 362
-- Data for Name: t_kozter_nev; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51601 (class 0 OID 26631544)
-- Dependencies: 407
-- Data for Name: t_ksh_kozig; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51602 (class 0 OID 26631548)
-- Dependencies: 408
-- Data for Name: t_lap; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51603 (class 0 OID 26631551)
-- Dependencies: 409
-- Data for Name: t_mas_rendszer_gy; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51604 (class 0 OID 26631554)
-- Dependencies: 410
-- Data for Name: t_megsz_datumg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51605 (class 0 OID 26631557)
-- Dependencies: 411
-- Data for Name: t_megsz_datumt; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51651 (class 0 OID 188629783)
-- Dependencies: 611
-- Data for Name: t_muvel_ag; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--

INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (1, 'szántó');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (2, 'rét');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (3, 'szőlő');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (4, 'kert');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (5, 'gyümölcsös');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (6, 'legelő');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (7, 'nádas');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (8, 'erdő');
INSERT INTO datr_sablon.t_muvel_ag (kod, ertek) VALUES (9, 'kivett');


--
-- TOC entry 51606 (class 0 OID 26631560)
-- Dependencies: 412
-- Data for Name: t_obj_attraa; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51607 (class 0 OID 26631563)
-- Dependencies: 413
-- Data for Name: t_obj_attrab; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51608 (class 0 OID 26631566)
-- Dependencies: 414
-- Data for Name: t_obj_attrac; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51609 (class 0 OID 26631569)
-- Dependencies: 415
-- Data for Name: t_obj_attrad; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51576 (class 0 OID 26631431)
-- Dependencies: 375
-- Data for Name: t_obj_attrba; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51577 (class 0 OID 26631439)
-- Dependencies: 377
-- Data for Name: t_obj_attrbb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51565 (class 0 OID 26631319)
-- Dependencies: 353
-- Data for Name: t_obj_attrbc; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51566 (class 0 OID 26631325)
-- Dependencies: 354
-- Data for Name: t_obj_attrbd; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51578 (class 0 OID 26631457)
-- Dependencies: 381
-- Data for Name: t_obj_attrbe; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51610 (class 0 OID 26631572)
-- Dependencies: 416
-- Data for Name: t_obj_attrbe_ujabb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51579 (class 0 OID 26631465)
-- Dependencies: 383
-- Data for Name: t_obj_attrbf; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51611 (class 0 OID 26631575)
-- Dependencies: 417
-- Data for Name: t_obj_attrbf_ujabb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51580 (class 0 OID 26631473)
-- Dependencies: 385
-- Data for Name: t_obj_attrbg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51612 (class 0 OID 26631578)
-- Dependencies: 418
-- Data for Name: t_obj_attrbg_ujabb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51613 (class 0 OID 26631581)
-- Dependencies: 419
-- Data for Name: t_obj_attrbh; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51614 (class 0 OID 26631584)
-- Dependencies: 420
-- Data for Name: t_obj_attrbi; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51615 (class 0 OID 26631587)
-- Dependencies: 421
-- Data for Name: t_obj_attrca; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51616 (class 0 OID 26631590)
-- Dependencies: 422
-- Data for Name: t_obj_attrcb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51617 (class 0 OID 26631593)
-- Dependencies: 423
-- Data for Name: t_obj_attrcc; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51618 (class 0 OID 26631596)
-- Dependencies: 424
-- Data for Name: t_obj_attrcc_ujabb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51619 (class 0 OID 26631599)
-- Dependencies: 425
-- Data for Name: t_obj_attrcd; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51620 (class 0 OID 26631602)
-- Dependencies: 426
-- Data for Name: t_obj_attrcd_ujabb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51621 (class 0 OID 26631605)
-- Dependencies: 427
-- Data for Name: t_obj_attrce; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51622 (class 0 OID 26631608)
-- Dependencies: 428
-- Data for Name: t_obj_attrce_ujabb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51623 (class 0 OID 26631611)
-- Dependencies: 429
-- Data for Name: t_obj_attrda; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51624 (class 0 OID 26631614)
-- Dependencies: 430
-- Data for Name: t_obj_attrdb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51625 (class 0 OID 26631617)
-- Dependencies: 431
-- Data for Name: t_obj_attrdc; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51626 (class 0 OID 26631620)
-- Dependencies: 432
-- Data for Name: t_obj_attrdd; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51627 (class 0 OID 26631623)
-- Dependencies: 433
-- Data for Name: t_obj_attrde; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51628 (class 0 OID 26631626)
-- Dependencies: 434
-- Data for Name: t_obj_attrdf; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51629 (class 0 OID 26631629)
-- Dependencies: 435
-- Data for Name: t_obj_attrdg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51630 (class 0 OID 26631632)
-- Dependencies: 436
-- Data for Name: t_obj_attrea; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51631 (class 0 OID 26631635)
-- Dependencies: 437
-- Data for Name: t_obj_attreb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51632 (class 0 OID 26631638)
-- Dependencies: 438
-- Data for Name: t_obj_attrfa; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51633 (class 0 OID 26631641)
-- Dependencies: 439
-- Data for Name: t_obj_attrfb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51634 (class 0 OID 26631644)
-- Dependencies: 440
-- Data for Name: t_obj_attrfc; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51635 (class 0 OID 26631647)
-- Dependencies: 441
-- Data for Name: t_obj_attrga; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51636 (class 0 OID 26631650)
-- Dependencies: 442
-- Data for Name: t_obj_attrgb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51637 (class 0 OID 26631653)
-- Dependencies: 443
-- Data for Name: t_obj_attrha; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51638 (class 0 OID 26631656)
-- Dependencies: 444
-- Data for Name: t_obj_attrhb; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51639 (class 0 OID 26631659)
-- Dependencies: 445
-- Data for Name: t_obj_attrhc; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51640 (class 0 OID 26631662)
-- Dependencies: 446
-- Data for Name: t_orpont_gy; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51641 (class 0 OID 26631665)
-- Dependencies: 447
-- Data for Name: t_osadatal12; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51642 (class 0 OID 26631671)
-- Dependencies: 448
-- Data for Name: t_osszekot_iv; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51568 (class 0 OID 26631347)
-- Dependencies: 358
-- Data for Name: t_pont; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51643 (class 0 OID 26631674)
-- Dependencies: 449
-- Data for Name: t_qgeometria; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51644 (class 0 OID 26631677)
-- Dependencies: 450
-- Data for Name: t_szemely; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51645 (class 0 OID 26631680)
-- Dependencies: 451
-- Data for Name: t_szimbolum; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51646 (class 0 OID 26631683)
-- Dependencies: 452
-- Data for Name: t_teljesseg; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51647 (class 0 OID 26631689)
-- Dependencies: 453
-- Data for Name: t_veg_cspont; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51648 (class 0 OID 26631692)
-- Dependencies: 454
-- Data for Name: t_veg_cspont_el; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 51572 (class 0 OID 26631379)
-- Dependencies: 365
-- Data for Name: t_vonal; Type: TABLE DATA; Schema: datr_sablon; Owner: postgres
--



--
-- TOC entry 48864 (class 2606 OID 39902765)
-- Name: t_obj_attrad pk_cimkoord_id; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrad
    ADD CONSTRAINT pk_cimkoord_id PRIMARY KEY (cimkoord_id);


--
-- TOC entry 48816 (class 2606 OID 39902767)
-- Name: t_felirat pk_t_felirat; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_felirat
    ADD CONSTRAINT pk_t_felirat PRIMARY KEY (id);


--
-- TOC entry 48895 (class 2606 OID 188629764)
-- Name: t_felirat_jelleg pk_t_felirat_jelleg; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_felirat_jelleg
    ADD CONSTRAINT pk_t_felirat_jelleg PRIMARY KEY (kod);


--
-- TOC entry 48828 (class 2606 OID 39902769)
-- Name: t_felulet pk_t_felulet; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_felulet
    ADD CONSTRAINT pk_t_felulet PRIMARY KEY (felulet_id, subfel_id, hatar_id, hatar_valt);


--
-- TOC entry 48897 (class 2606 OID 188629770)
-- Name: t_font pk_t_font; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_font
    ADD CONSTRAINT pk_t_font PRIMARY KEY (kod);


--
-- TOC entry 48823 (class 2606 OID 39902771)
-- Name: t_hatar pk_t_hatar; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_hatar
    ADD CONSTRAINT pk_t_hatar PRIMARY KEY (hatar_id, hsub_id);


--
-- TOC entry 48825 (class 2606 OID 39902773)
-- Name: t_hatarvonal pk_t_hatarvonal; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_hatarvonal
    ADD CONSTRAINT pk_t_hatarvonal PRIMARY KEY (hatarvonal_id, hvsub_id);


--
-- TOC entry 48899 (class 2606 OID 188629787)
-- Name: t_muvel_ag pk_t_muvel_ag; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_muvel_ag
    ADD CONSTRAINT pk_t_muvel_ag PRIMARY KEY (kod);


--
-- TOC entry 48855 (class 2606 OID 39902775)
-- Name: t_obj_attraa pk_t_obj_attraa; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attraa
    ADD CONSTRAINT pk_t_obj_attraa PRIMARY KEY (alappont_id);


--
-- TOC entry 48858 (class 2606 OID 39902777)
-- Name: t_obj_attrab pk_t_obj_attrab; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrab
    ADD CONSTRAINT pk_t_obj_attrab PRIMARY KEY (malapp_id);


--
-- TOC entry 48861 (class 2606 OID 39902779)
-- Name: t_obj_attrac pk_t_obj_attrac; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrac
    ADD CONSTRAINT pk_t_obj_attrac PRIMARY KEY (rpont_id);


--
-- TOC entry 48831 (class 2606 OID 39902781)
-- Name: t_obj_attrba pk_t_obj_attrba; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrba
    ADD CONSTRAINT pk_t_obj_attrba PRIMARY KEY (kozig_idba);


--
-- TOC entry 48834 (class 2606 OID 39902783)
-- Name: t_obj_attrbb pk_t_obj_attrbb; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbb
    ADD CONSTRAINT pk_t_obj_attrbb PRIMARY KEY (kozigal_id);


--
-- TOC entry 48808 (class 2606 OID 39902785)
-- Name: t_obj_attrbc pk_t_obj_attrbc; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbc
    ADD CONSTRAINT pk_t_obj_attrbc PRIMARY KEY (parcel_id);


--
-- TOC entry 48812 (class 2606 OID 39902787)
-- Name: t_obj_attrbd pk_t_obj_attrbd; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbd
    ADD CONSTRAINT pk_t_obj_attrbd PRIMARY KEY (parcel_id);


--
-- TOC entry 48837 (class 2606 OID 39902789)
-- Name: t_obj_attrbe pk_t_obj_attrbe; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbe
    ADD CONSTRAINT pk_t_obj_attrbe PRIMARY KEY (alreszlet_id);


--
-- TOC entry 48867 (class 2606 OID 39902791)
-- Name: t_obj_attrbe_ujabb pk_t_obj_attrbe_ujabb; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbe_ujabb
    ADD CONSTRAINT pk_t_obj_attrbe_ujabb PRIMARY KEY (alreszlet_id);


--
-- TOC entry 48840 (class 2606 OID 39902793)
-- Name: t_obj_attrbf pk_t_obj_attrbf; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbf
    ADD CONSTRAINT pk_t_obj_attrbf PRIMARY KEY (moszt_id);


--
-- TOC entry 48870 (class 2606 OID 39902795)
-- Name: t_obj_attrbf_ujabb pk_t_obj_attrbf_ujabb; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbf_ujabb
    ADD CONSTRAINT pk_t_obj_attrbf_ujabb PRIMARY KEY (moszt_id);


--
-- TOC entry 48843 (class 2606 OID 39902797)
-- Name: t_obj_attrbg pk_t_obj_attrbg; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbg
    ADD CONSTRAINT pk_t_obj_attrbg PRIMARY KEY (eoi_id);


--
-- TOC entry 48873 (class 2606 OID 39902799)
-- Name: t_obj_attrbg_ujabb pk_t_obj_attrbg_ujabb; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbg_ujabb
    ADD CONSTRAINT pk_t_obj_attrbg_ujabb PRIMARY KEY (eoi_id);


--
-- TOC entry 48875 (class 2606 OID 39902801)
-- Name: t_obj_attrbh pk_t_obj_attrbh; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbh
    ADD CONSTRAINT pk_t_obj_attrbh PRIMARY KEY (szolg_id);


--
-- TOC entry 48877 (class 2606 OID 39902803)
-- Name: t_obj_attrbi pk_t_obj_attrbi; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_obj_attrbi
    ADD CONSTRAINT pk_t_obj_attrbi PRIMARY KEY (mintater_id);


--
-- TOC entry 48819 (class 2606 OID 39902805)
-- Name: t_pont pk_t_pont; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_pont
    ADD CONSTRAINT pk_t_pont PRIMARY KEY (pont_id);


--
-- TOC entry 48821 (class 2606 OID 39902807)
-- Name: t_vonal pk_t_vonal; Type: CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_vonal
    ADD CONSTRAINT pk_t_vonal PRIMARY KEY (vonal_id, vsub_id);


--
-- TOC entry 48893 (class 1259 OID 188629782)
-- Name: fki_felirat_2_font; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_felirat_2_font ON datr_sablon.t_felirat_jelleg USING btree (font_id);


--
-- TOC entry 48813 (class 1259 OID 188629776)
-- Name: fki_felirat_2_jelleg; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_felirat_2_jelleg ON datr_sablon.t_felirat USING btree (jelleg_kod);


--
-- TOC entry 48844 (class 1259 OID 39908283)
-- Name: fki_t_el_2_t_hatarvonal_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_el_2_t_hatarvonal_id ON datr_sablon.t_el USING btree (hatarvonal_id);


--
-- TOC entry 48845 (class 1259 OID 39908284)
-- Name: fki_t_el_2_t_vonal_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_el_2_t_vonal_id ON datr_sablon.t_el USING btree (vonal_id);


--
-- TOC entry 48846 (class 1259 OID 39908285)
-- Name: fki_t_gyuru_2_t_hatar_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_gyuru_2_t_hatar_id ON datr_sablon.t_gyuru USING btree (hatar_id);


--
-- TOC entry 48847 (class 1259 OID 39908286)
-- Name: fki_t_izolalt_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_izolalt_2_t_pont_id ON datr_sablon.t_izolalt USING btree (pont_id);


--
-- TOC entry 48848 (class 1259 OID 39908287)
-- Name: fki_t_izolalt_l_2_t_lap_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_izolalt_l_2_t_lap_id ON datr_sablon.t_izolalt_l USING btree (lap_id);


--
-- TOC entry 48849 (class 1259 OID 39908288)
-- Name: fki_t_kozb_cspont_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_kozb_cspont_2_t_pont_id ON datr_sablon.t_kozb_cspont USING btree (pont_id);


--
-- TOC entry 48850 (class 1259 OID 39908289)
-- Name: fki_t_kozb_cspont_el_2_t_el_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_kozb_cspont_el_2_t_el_id ON datr_sablon.t_kozb_cspont_el USING btree (el_id);


--
-- TOC entry 48851 (class 1259 OID 39908290)
-- Name: fki_t_kozb_cspont_gy_2_t_gyuru_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_kozb_cspont_gy_2_t_gyuru_id ON datr_sablon.t_kozb_cspont_gy USING btree (gyuru_id);


--
-- TOC entry 48852 (class 1259 OID 39908291)
-- Name: fki_t_lap_2_t_gyuru_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_lap_2_t_gyuru_id ON datr_sablon.t_lap USING btree (gyuru_id);


--
-- TOC entry 48853 (class 1259 OID 39908292)
-- Name: fki_t_obj_attraa_2_t_pont; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attraa_2_t_pont ON datr_sablon.t_obj_attraa USING btree (pont_id);


--
-- TOC entry 48856 (class 1259 OID 39908293)
-- Name: fki_t_obj_attrab_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrab_2_t_pont_id ON datr_sablon.t_obj_attrab USING btree (pont_id);


--
-- TOC entry 48859 (class 1259 OID 39908294)
-- Name: fki_t_obj_attrac_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrac_2_t_pont_id ON datr_sablon.t_obj_attrac USING btree (pont_id);


--
-- TOC entry 48862 (class 1259 OID 39908295)
-- Name: fki_t_obj_attrad_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrad_2_t_pont_id ON datr_sablon.t_obj_attrad USING btree (pont_id);


--
-- TOC entry 48829 (class 1259 OID 39908296)
-- Name: fki_t_obj_attrba_2_t_felulet; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrba_2_t_felulet ON datr_sablon.t_obj_attrba USING btree (felulet_id);


--
-- TOC entry 48832 (class 1259 OID 39908297)
-- Name: fki_t_obj_attrbb_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbb_2_t_felulet_id ON datr_sablon.t_obj_attrbb USING btree (felulet_id);


--
-- TOC entry 48805 (class 1259 OID 39908298)
-- Name: fki_t_obj_attrbc_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbc_2_t_felulet_id ON datr_sablon.t_obj_attrbc USING btree (felulet_id);


--
-- TOC entry 48809 (class 1259 OID 39908299)
-- Name: fki_t_obj_attrbd_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbd_2_t_felulet_id ON datr_sablon.t_obj_attrbd USING btree (felulet_id);


--
-- TOC entry 48835 (class 1259 OID 39908300)
-- Name: fki_t_obj_attrbe_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbe_2_t_felulet_id ON datr_sablon.t_obj_attrbe USING btree (felulet_id);


--
-- TOC entry 48865 (class 1259 OID 39908301)
-- Name: fki_t_obj_attrbe_ujabb_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbe_ujabb_2_t_felulet_id ON datr_sablon.t_obj_attrbe_ujabb USING btree (felulet_id);


--
-- TOC entry 48838 (class 1259 OID 39908302)
-- Name: fki_t_obj_attrbf_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbf_2_t_felulet_id ON datr_sablon.t_obj_attrbf USING btree (felulet_id);


--
-- TOC entry 48868 (class 1259 OID 39908303)
-- Name: fki_t_obj_attrbf_ujabb_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbf_ujabb_2_t_felulet_id ON datr_sablon.t_obj_attrbf_ujabb USING btree (felulet_id);


--
-- TOC entry 48841 (class 1259 OID 39908304)
-- Name: fki_t_obj_attrbg_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbg_2_t_felulet_id ON datr_sablon.t_obj_attrbg USING btree (felulet_id);


--
-- TOC entry 48871 (class 1259 OID 39908305)
-- Name: fki_t_obj_attrbg_ujabb_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrbg_ujabb_2_t_felulet_id ON datr_sablon.t_obj_attrbg_ujabb USING btree (felulet_id);


--
-- TOC entry 48878 (class 1259 OID 39908306)
-- Name: fki_t_obj_attrca_2_t_felulet_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrca_2_t_felulet_id ON datr_sablon.t_obj_attrca USING btree (felulet_id);


--
-- TOC entry 48879 (class 1259 OID 39908307)
-- Name: fki_t_obj_attrca_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrca_2_t_pont_id ON datr_sablon.t_obj_attrca USING btree (pont_id);


--
-- TOC entry 48880 (class 1259 OID 39908308)
-- Name: fki_t_obj_attrcb_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrcb_2_t_pont_id ON datr_sablon.t_obj_attrcb USING btree (pont_id);


--
-- TOC entry 48881 (class 1259 OID 39908309)
-- Name: fki_t_obj_attrcc_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrcc_2_t_pont_id ON datr_sablon.t_obj_attrcc USING btree (pont_id);


--
-- TOC entry 48882 (class 1259 OID 39908310)
-- Name: fki_t_obj_attrcc_ujabb_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrcc_ujabb_2_t_pont_id ON datr_sablon.t_obj_attrcc_ujabb USING btree (pont_id);


--
-- TOC entry 48883 (class 1259 OID 39908311)
-- Name: fki_t_obj_attrcd_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrcd_2_t_pont_id ON datr_sablon.t_obj_attrcd USING btree (pont_id);


--
-- TOC entry 48884 (class 1259 OID 39908312)
-- Name: fki_t_obj_attrcd_ujabb_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrcd_ujabb_2_t_pont_id ON datr_sablon.t_obj_attrcd_ujabb USING btree (pont_id);


--
-- TOC entry 48885 (class 1259 OID 39908313)
-- Name: fki_t_obj_attrce_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrce_2_t_pont_id ON datr_sablon.t_obj_attrce USING btree (pont_id);


--
-- TOC entry 48886 (class 1259 OID 39908314)
-- Name: fki_t_obj_attrce_ujabb_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrce_ujabb_2_t_pont_id ON datr_sablon.t_obj_attrce_ujabb USING btree (pont_id);


--
-- TOC entry 48887 (class 1259 OID 39908316)
-- Name: fki_t_obj_attrda_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrda_2_t_pont_id ON datr_sablon.t_obj_attrda USING btree (pont_id);


--
-- TOC entry 48888 (class 1259 OID 39908317)
-- Name: fki_t_obj_attrhb_2_t_felulet; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_obj_attrhb_2_t_felulet ON datr_sablon.t_obj_attrhb USING btree (felulet_id);


--
-- TOC entry 48889 (class 1259 OID 39908318)
-- Name: fki_t_veg_cspont_2_t_pont_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_veg_cspont_2_t_pont_id ON datr_sablon.t_veg_cspont USING btree (pont_id);


--
-- TOC entry 48890 (class 1259 OID 39908319)
-- Name: fki_t_veg_cspont_el_2_t_el_id; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_veg_cspont_el_2_t_el_id ON datr_sablon.t_veg_cspont_el USING btree (el_id);


--
-- TOC entry 48891 (class 1259 OID 39908320)
-- Name: fki_t_veg_cspont_el_2_t_veg_cspont_id1; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_veg_cspont_el_2_t_veg_cspont_id1 ON datr_sablon.t_veg_cspont_el USING btree (veg_cspont_id1);


--
-- TOC entry 48892 (class 1259 OID 39908321)
-- Name: fki_t_veg_cspont_el_2_t_veg_cspont_id2; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX fki_t_veg_cspont_el_2_t_veg_cspont_id2 ON datr_sablon.t_veg_cspont_el USING btree (veg_cspont_id2);


--
-- TOC entry 48814 (class 1259 OID 39908322)
-- Name: i_t_felirat_geometria; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX i_t_felirat_geometria ON datr_sablon.t_felirat USING gist (geometria);


--
-- TOC entry 48826 (class 1259 OID 39908323)
-- Name: i_t_felulet_geometria; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX i_t_felulet_geometria ON datr_sablon.t_felulet USING gist (geometria);


--
-- TOC entry 48806 (class 1259 OID 39908324)
-- Name: i_t_obj_attrbc_geometria; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX i_t_obj_attrbc_geometria ON datr_sablon.t_obj_attrbc USING gist (geometria);


--
-- TOC entry 48810 (class 1259 OID 39908325)
-- Name: i_t_obj_attrbd_geometria; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX i_t_obj_attrbd_geometria ON datr_sablon.t_obj_attrbd USING gist (geometria);


--
-- TOC entry 48817 (class 1259 OID 39908326)
-- Name: i_t_pont_geometria; Type: INDEX; Schema: datr_sablon; Owner: postgres
--

CREATE INDEX i_t_pont_geometria ON datr_sablon.t_pont USING gist (geometria);


--
-- TOC entry 48901 (class 2606 OID 188629777)
-- Name: t_felirat_jelleg fk_felirat_2_font; Type: FK CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_felirat_jelleg
    ADD CONSTRAINT fk_felirat_2_font FOREIGN KEY (font_id) REFERENCES datr_sablon.t_font(kod) ON UPDATE CASCADE;


--
-- TOC entry 48900 (class 2606 OID 188629771)
-- Name: t_felirat fk_felirat_2_jelleg; Type: FK CONSTRAINT; Schema: datr_sablon; Owner: postgres
--

ALTER TABLE ONLY datr_sablon.t_felirat
    ADD CONSTRAINT fk_felirat_2_jelleg FOREIGN KEY (jelleg_kod) REFERENCES datr_sablon.t_felirat_jelleg(kod) ON UPDATE CASCADE;


-- Completed on 2020-08-10 07:34:35

--
-- PostgreSQL database dump complete
--

