IF EXISTS ( SELECT * FROM dbo.sysobjects WHERE id = object_id(N'dbo.udf_getTableHasPK') AND xtype IN (N'FN', N'IF', N'TF')) DROP FUNCTION dbo.udf_getTableHasPK
IF EXISTS ( SELECT * FROM dbo.sysobjects WHERE id = object_id(N'dbo.udf_getTableColumnInfo') AND xtype IN (N'FN', N'IF', N'TF')) DROP FUNCTION dbo.udf_getTableColumnInfo
IF EXISTS ( SELECT * FROM dbo.sysobjects WHERE id = object_id(N'dbo.udf_getTableColumnInfo2') AND xtype IN (N'FN', N'IF', N'TF')) DROP FUNCTION dbo.udf_getTableColumnInfo2
IF EXISTS ( SELECT * FROM dbo.sysobjects WHERE id = object_id(N'dbo.udf_isColumnPK') AND xtype IN (N'FN', N'IF', N'TF')) DROP FUNCTION dbo.udf_isColumnPK
GO

CREATE FUNCTION dbo.udf_isColumnPK( @sTableName varchar(128), @nColumnName varchar(128) )
RETURNS bit
AS
BEGIN
	DECLARE		@nTableID int
			,	@nIndexID int
			,	@i int
	
	SET			@nTableID = OBJECT_ID(@sTableName)
	
	SELECT 		@nIndexID = indid
	FROM 		sysindexes
	WHERE 		(id = @nTableID)
		AND	 	(indid BETWEEN 1 AND 254)
		AND		((status & 2048) = 2048)
	
	IF( @nIndexID IS NULL )
		RETURN 0
	
	IF( @nColumnName IN (
		SELECT		sc.[name]
		FROM 		sysindexkeys sik
		INNER JOIN	syscolumns sc ON sik.id = sc.id AND sik.colid = sc.colid
		WHERE 		(sik.id = @nTableID)
			AND 	(sik.indid = @nIndexID)
	) )
		RETURN 1
	
	RETURN 0
END
GO

CREATE FUNCTION dbo.udf_getTableColumnInfo( @sTableName varchar(128) )
RETURNS TABLE
AS
	RETURN
	SELECT		c.name AS sColumnName
			,	t.name AS sTypeName
			,	c.colid AS nColumnID
			,	CASE WHEN ( t.name = 'VARCHAR' AND c.length = -1 ) THEN CONVERT( VARCHAR(4), 'MAX' ) ELSE CONVERT( VARCHAR(4), c.length ) END AS nColumnLength
			,	c.prec AS nColumnPrecision
			,	c.scale AS nColumnScale
			,	c.isNullable
			,	c.isComputed
			,	SIGN(c.status & 128) AS isIdentity
			,	CASE WHEN ( t.name IN ('TEXT', 'NTEXT', 'TIMESTAMP', 'BINARY', 'VARBINARY', 'IMAGE') ) THEN 0 ELSE 1 END AS isSearchable
			,	SUBSTRING( ic.column_default, 2, len(ic.column_default)-2 ) AS sDefaultValue
			,	dbo.udf_isColumnPK(@sTableName, c.name) AS bPrimaryKeyColumn
			,	CASE 	WHEN t.name IN ('CHAR', 'VARCHAR', 'BINARY', 'VARBINARY', 'NCHAR', 'NVARCHAR') THEN 1
						WHEN t.name IN ('DECIMAL', 'NUMERIC') THEN 2
						ELSE 0
				END AS nTypeGroup
	FROM		syscolumns AS c 
	INNER JOIN	systypes AS t
		ON		(c.xtype = t.xtype and c.usertype = t.usertype)
	INNER JOIN	INFORMATION_SCHEMA.Columns AS ic
		ON		((c.colid = ic.ordinal_position))
	WHERE		(c.id = OBJECT_ID(@sTableName))
		AND		(ic.table_name = @sTableName)
GO

CREATE FUNCTION dbo.udf_getTableColumnInfo2( @sTableName varchar(128) )
RETURNS TABLE
AS
	RETURN
	SELECT		column_name AS sColumnName
			,	data_type AS sTypeName
		--	,	COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'ColumnID') AS nColumnID
			,	ordinal_position AS nColumnID
			,	character_octet_length AS nColumnLength
			,	numeric_precision AS nColumnPrecision
			,	numeric_scale AS nColumnScale
			,	CASE WHEN ( is_nullable = 'NO' ) THEN 0 ELSE 1 END AS isNullable
			,	COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsComputed') AS isComputed
			,	COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') AS isIdentity
			,	CASE WHEN ( data_type IN ('text', 'ntext', 'timestamp', 'binary', 'varbinary', 'image') ) THEN 0 ELSE 1 END AS isSearchable
			,	CASE
					WHEN column_default IS NULL THEN NULL
					WHEN ( LEFT( column_default, 1 ) = '(' AND RIGHT( column_default, 1 ) = ')' ) THEN SUBSTRING( column_default, 2, LEN( column_default ) - 2 )
					ELSE column_default
				END AS sDefaultValue
			,	dbo.udf_isColumnPK( table_name, column_name ) AS bPrimaryKeyColumn
			,	CASE 	WHEN data_type IN ('char', 'varchar', 'binary', 'varbinary', 'nchar', 'nvarchar') THEN 1
						WHEN data_type IN ('decimal', 'numeric') THEN 2
						ELSE 0
				END AS nTypeGroup
	FROM		INFORMATION_SCHEMA.Columns
	WHERE		(table_name = @sTableName)
GO

CREATE FUNCTION dbo.udf_getTableHasPK( @sTableName varchar(128) )
RETURNS bit
AS
BEGIN
	DECLARE		@nTableID int
			,	@nIndexID int
	
	SET 		@nTableID = OBJECT_ID(@sTableName)
	
	SELECT 		@nIndexID = indid
	FROM 		sysindexes
	WHERE 		(id = @nTableID)
		AND 	(indid BETWEEN 1 AND 254) 
		AND 	((status & 2048) = 2048)
	
	IF( @nIndexID IS NOT NULL )
		RETURN 1
	
	RETURN 0
END
GO