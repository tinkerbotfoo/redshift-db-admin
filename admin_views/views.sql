CREATE SCHEMA DBADMIN;

GRANT USAGE ON SCHEMA DBADMIN TO PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA DBADMIN TO PUBLIC;

--========================================================
--                    TAB_COLS 
-- Table Column Information
--========================================================
--DROP VIEW DBADMIN.TAB_COLS;
CREATE
	OR
REPLACE
	VIEW DBADMIN.TAB_COLS AS 
SELECT
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
	END                                            AS dist_key ,
	d.compression,
	d.notnull,
	d.encoding,
	d.type,
	d.sortkey,
	d.distkey 
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
						a.attname  AS colname ,
						pg_catalog.format_type(a.atttypid,
						a.atttypmod) AS TYPE ,
		pg_catalog.format_encoding(a.attencodingtype) AS encoding ,
	a.attisdistkey               AS distkey ,
	a.attsortkeyord              AS sortkey ,
	a.attnotnull                 AS notnull ,
	a.attencodingtype            AS compression 
FROM
	pg_attribute a 
WHERE
	(((a.attnum > 0) AND
	(NOT a.attisdropped)) AND
	(a.attisdistkey = TRUE))) d ON (((t.tableid = d.tableid) AND
	((C.column_name)::NAME = d.colname))))
;

SELECT count(*) FROM DBADMIN.TAB_COLS LIMIT 10;


--========================================================
--                    TAB_SIZE 
-- Table size & record count
-- Reference : https://aboutdatabases.wordpress.com/2015/01/24/amazon-redshift-how-to-get-the-sizes-of-all-tables/
--========================================================
CREATE
	OR
REPLACE
	VIEW DBADMIN.TAB_SIZE AS 
SELECT
	CAST(use2.usename AS VARCHAR(50)) AS OWNER ,
	TRIM(pgdb.datname)              AS DATABASE ,
	TRIM(pgn.nspname)               AS SCHEMA ,
	TRIM(a.NAME)                    AS TABLE ,
	(b.mbytes) / 1024               AS Gigabytes ,
	b.mbytes                        AS Megabytes ,
	a.ROWS 
FROM
	(	SELECT
			db_id ,
			id ,
			NAME ,
			SUM(ROWS) AS ROWS 
		FROM
			stv_tbl_perm a 
		GROUP BY
			db_id ,
			id ,
			NAME ) AS a 
		JOIN pg_class AS pgc 
		ON pgc.oid = a.id 
			LEFT JOIN pg_user use2 
			ON (pgc.relowner = use2.usesysid) 
				JOIN pg_namespace AS pgn 
				ON pgn.oid = pgc.relnamespace AND
				pgn.nspowner > 1 
					JOIN pg_database AS pgdb 
					ON pgdb.oid = a.db_id 
						JOIN (	SELECT
									tbl ,
									COUNT(*) AS mbytes 
								FROM
									stv_blocklist 
								GROUP BY
									tbl ) b 
						ON a.id = b.tbl 
ORDER BY
	mbytes DESC ,
	a.db_id ,
	a.NAME
;

SELECT * FROM DBADMIN.TAB_SIZE LIMIT 10;


--========================================================
--                    DISK_USAGE 
-- Disk space usage
--========================================================
CREATE
	OR
REPLACE
	VIEW DBADMIN.DISK_USAGE AS 
SELECT
	owner AS node,
	diskno,
	used,
	capacity 
FROM
	stv_partitions 
ORDER BY
	1,
	2,
	3,
	4
;

select * from dbadmin.disk_usage;


