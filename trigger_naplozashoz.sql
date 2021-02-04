-- https://www.postgresql.org/docs/12/plpgsql-trigger.html

DROP SCHEMA IF EXISTS example CASCADE;
DROP ROLE IF EXISTS example_user;


CREATE SCHEMA example AUTHORIZATION postgres;

CREATE TABLE example.data
(
  id serial NOT NULL,
  name text,
  value numeric,
  CONSTRAINT pk_data PRIMARY KEY (id)
)
WITH ( OIDS=FALSE );

CREATE TABLE example.data_log
(
  id serial NOT NULL,
  data_id integer,
  name text,
  value numeric,
  mu text,
  md timestamp without time zone,
  CONSTRAINT pk_data_log PRIMARY KEY (id),
  CONSTRAINT fk_data_log FOREIGN KEY (data_id) REFERENCES example.data (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH ( OIDS=FALSE );

CREATE OR REPLACE FUNCTION example.data_log()
  RETURNS trigger AS
$BODY$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            --INSERT INTO emp_audit SELECT 'D', now(), user, OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
            --INSERT INTO emp_audit SELECT 'U', now(), user, NEW.*;
            insert into example.data_log ( data_id, name, value, mu, md ) select OLD.*, user, now();
        ELSIF (TG_OP = 'INSERT') THEN
            --INSERT INTO emp_audit SELECT 'I', now(), user, NEW.*;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER u_data_logger AFTER UPDATE ON example.data FOR EACH ROW EXECUTE PROCEDURE example.data_log();


CREATE OR REPLACE VIEW example.data_log_join AS 
SELECT d.id data_id, d.name d_name, d.value d_value, l.id log_id, l.name l_name, l.value l_value, l.md
FROM example.data d
  LEFT JOIN example.data_log l ON l.data_id = d.id
ORDER BY d.id, l.id;

CREATE OR REPLACE VIEW example.data_log_union AS 
SELECT id data_id, NULL log_id, name, value, NULL md
FROM example.data
  UNION
SELECT data_id, id log_id, name, value, md
FROM example.data_log
ORDER BY 1, 2 DESC;


CREATE ROLE example_user LOGIN PASSWORD 'example' NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT USAGE ON SCHEMA example TO example_user;

GRANT SELECT, UPDATE, INSERT ON TABLE example.data TO example_user;
GRANT SELECT, INSERT ON TABLE example.data_log TO example_user;

GRANT UPDATE ON SEQUENCE example.data_id_seq TO example_user;
GRANT UPDATE ON SEQUENCE example.data_log_id_seq TO example_user;

GRANT SELECT ON TABLE example.data_log_join TO example_user;
GRANT SELECT ON TABLE example.data_log_union TO example_user;
