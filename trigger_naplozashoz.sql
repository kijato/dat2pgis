-- https://www.postgresql.org/docs/12/plpgsql-trigger.html

-- DROP TABLE meta.teszt;
CREATE TABLE meta.teszt
(
  id serial NOT NULL,
  nev text,
  ertek numeric,
  CONSTRAINT pk_teszt PRIMARY KEY (id)
)
WITH ( OIDS=FALSE);

ALTER TABLE meta.teszt OWNER TO postgres;


-- DROP TABLE meta.teszt_naplo;
CREATE TABLE meta.teszt_naplo
(
  naplo_id serial,
  id integer,
  nev text,
  ertek numeric,
  mu character varying(10),
  md timestamp without time zone,
  CONSTRAINT pk_teszt_naplo PRIMARY KEY (naplo_id),
  CONSTRAINT fk_teszt_naplo FOREIGN KEY (id) REFERENCES meta.teszt (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH ( OIDS=FALSE );

ALTER TABLE meta.teszt_naplo OWNER TO postgres;

-- DROP INDEX meta.fki_teszt_naplo;
CREATE INDEX fki_teszt_naplo ON meta.teszt_naplo USING btree (id);


-- DROP FUNCTION meta.teszt_naplo();
CREATE OR REPLACE FUNCTION meta.teszt_naplo()
  RETURNS trigger AS
$BODY$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            --INSERT INTO emp_audit SELECT 'D', now(), user, OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
            --INSERT INTO emp_audit SELECT 'U', now(), user, NEW.*;
            insert into meta.teszt_naplo (id,nev,ertek,mu,md) select OLD.*, user, now();
        ELSIF (TG_OP = 'INSERT') THEN
            --INSERT INTO emp_audit SELECT 'I', now(), user, NEW.*;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION meta.teszt_naplo()
  OWNER TO postgres;

-- DROP TRIGGER u_naplo ON meta.teszt;
CREATE TRIGGER u_naplo
  AFTER UPDATE
  ON meta.teszt
  FOR EACH ROW
  EXECUTE PROCEDURE meta.teszt_naplo();


+ adandó jogok:

GRANT SELECT, UPDATE, INSERT ON TABLE meta.teszt TO admin;
GRANT SELECT, INSERT ON TABLE meta.teszt_naplo TO admin;

GRANT SELECT, UPDATE ON SEQUENCE meta.teszt_id_seq TO admin;
GRANT SELECT, UPDATE ON SEQUENCE meta.teszt_naplo_naplo_id_seq TO admin;


+ nézetek:

CREATE OR REPLACE VIEW takaros.teszt_naplo_join AS 
 SELECT t.id,
    t.nev,
    t.ertek,
    n.naplo_id,
    n.nev AS naplo_nev,
    n.ertek AS naplo_ertek
   FROM takaros.teszt t
     LEFT JOIN takaros.teszt_naplo n ON n.id = t.id
  ORDER BY t.id, n.naplo_id;
  
  CREATE OR REPLACE VIEW takaros.teszt_naplo_union AS 
 SELECT teszt.id,
    NULL::integer AS naplo_id,
    teszt.nev,
    teszt.ertek
   FROM takaros.teszt
UNION
 SELECT teszt_naplo.id,
    teszt_naplo.naplo_id,
    teszt_naplo.nev,
    teszt_naplo.ertek
   FROM takaros.teszt_naplo
  ORDER BY 1, 2 DESC;
  


