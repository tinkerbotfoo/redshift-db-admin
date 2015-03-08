CREATE SCHEMA DBADMIN;

GRANT USAGE ON SCHEMA DBADMIN TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA DBADMIN TO PUBLIC;

CREATE
	OR
REPLACE
	VIEW DBADMIN.TABCOLS AS 
SELECT
	derived_table1.tableid,
	derived_table1.table_schema,
	derived_table1.table_name,
	derived_table1.column_name,
	derived_table1.ordinal_position,
	derived_table1.column_default,
	derived_table1.is_nullable,
	derived_table1.udt_name,
	derived_table1.character_maximum_length,
	derived_table1.numeric_precision,
	derived_table1.numeric_scale,
	derived_table1.sort_col_order,
	derived_table1.dist_key 
FROM
	(	SELECT
			(t.tableid)::INTEGER                       AS tableid,
			(C.table_schema)::CHARACTER VARYING(100)   AS table_schema,
			(C.table_name)::CHARACTER VARYING(100)     AS TABLE_NAME,
			(C.column_name)::CHARACTER VARYING(100)    AS COLUMN_NAME,
			(C.ordinal_position)::INTEGER              AS ordinal_position,
			(C.column_default)::CHARACTER VARYING(100) AS column_default,
			(C.is_nullable)::CHARACTER VARYING(20)     AS is_nullable,
			(C.udt_name)::CHARACTER VARYING(50)        AS udt_name,
			(C.character_maximum_length)::INTEGER      AS character_maximum_length,
			C.numeric_precision,
			C.numeric_scale,
			s.sort_col_order,
			CASE 
				WHEN ((d.colname = NULL::NAME) OR
				((d.colname IS NULL) AND
				(NULL::"unknown" IS NULL))) 
				THEN 0 
				ELSE 1 
			END                                            AS dist_key 
		FROM
			(((information_schema.columns C 
			JOIN (	SELECT
						"substring"(((n.nspname)::CHARACTER VARYING)::text,
			1,
			100) AS schemaname,
			"substring"(((c.relname)::CHARACTER VARYING)::text,
	1,
	100)  AS tablename,
	C.oid AS tableid 
FROM
	pg_namespace n,
	pg_class C 
WHERE
	(((n.oid = C.relnamespace) AND
	(((n.nspname <> 'pg_catalog'::name) AND
	(n.nspname <> 'pg_toast'::name)) AND
	(n.nspname <> 'information_schema'::name))) AND
	(C.relname <> 'temp_staging_tables_1'::name))) t ON (((((C.table_schema):: CHARACTER VARYING)::text = t.schemaname) AND
	(((C.table_name)::CHARACTER VARYING)::text = t.tablename)))) 
		LEFT JOIN (	SELECT
						a.attrelid      AS tableid,
						a.attname       AS colname,
						a.attsortkeyord AS sort_col_order 
					FROM
						pg_attribute a 
					WHERE
						(((a.attnum > 0) AND
						(NOT a.attisdropped)) AND
						(a.attsortkeyord > 0))) s 
		ON (((t.tableid = s.tableid) AND
		((C.column_name)::NAME = s.colname)))) 
		LEFT JOIN (	SELECT
						a.attrelid AS tableid,
						a.attname  AS colname 
					FROM
						pg_attribute a 
					WHERE
						(((a.attnum > 0) AND
						(NOT a.attisdropped)) AND
						(a.attisdistkey = TRUE))) d 
		ON (((t.tableid = d.tableid) AND
		((C.column_name)::NAME = d.colname))))) derived_table1
;

SELECT * FROM DBADMIN.TABCOLS LIMIT 10;