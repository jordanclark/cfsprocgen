<!--- Copyright 2005 Imagineering Internet Inc. (imagineer.ca) and Jordan Clark (jclark@imagineeringstuido.com). All rights reserved.
Use of source and redistribution, with or without modification, are prohibited without prior written consent. --->

<cfcomponent output="false" displayName="genSproc2">

<cfproperty name="owner" type="string" default="dbo">
<cfproperty name="dsn" type="string" default="">

<!--- DEFAULT SETTINGS --->
<cfproperty name="sprocPrefix" type="string" default="gsp_" required="true" hint="Default Sproc Prefix">
<cfproperty name="updateSuffix" type="string" default="Update" required="true" hint="Default Update Sproc Suffix">
<cfproperty name="selectSuffix" type="string" default="Select" required="true" hint="Default Select Sproc Suffix">
<cfproperty name="insertSuffix" type="string" default="Insert" required="true" hint="Default Insert Sproc Suffix">
<cfproperty name="deleteSuffix" type="string" default="Delete" required="true" hint="Default Delete Sproc Suffix">
<cfproperty name="countSuffix" type="string" default="Count" required="true" hint="Default Count Sproc Suffix">
<cfproperty name="existsSuffix" type="string" default="Exists" required="true" hint="Default Exists Sproc Suffix">
<cfproperty name="saveSuffix" type="string" default="Save" required="true" hint="Default Save Sproc Suffix">
<cfproperty name="mergeSuffix" type="string" default="Merge" required="true" hint="Default Merge Sproc Suffix">
<cfproperty name="recordSuffix" type="string" default="Set" required="true" hint="Default Record Sproc Suffix">
<cfproperty name="setSuffix" type="string" default="Set" required="true" hint="Default Set Sproc Suffix">
<cfproperty name="allSuffix" type="string" default="All" required="true" hint="Default 'All' Sproc Suffix">
<cfproperty name="udfPrefix" type="string" default="db" required="true" hint="Default UDF Prefix">


<!-----------------------------------------------------------------------------------------------------------
-- INIT INTERNAL PROPERTIES
------------------------------------------------------------------------------------------------------------>


<cffunction name="init" output="false">
	<cfset this.owner = "dbo">
	<cfset this.separator = "/">
	<cfset this.sprocPrefix = "gsp_">
	<cfset this.updateSuffix = "Update">
	<cfset this.selectSuffix = "Select">
	<cfset this.selectSetSuffix = "SelectSet">
	<cfset this.selectAllSuffix = "SelectAll">
	<cfset this.selectRecordSuffix = "Record">
	<cfset this.insertSuffix = "Insert">
	<cfset this.deleteSuffix = "Delete">
	<cfset this.deleteAllSuffix = "DeleteAll">
	<cfset this.countSuffix = "Count">
	<cfset this.existsSuffix = "Exists">
	<cfset this.saveSuffix = "Save">
	<cfset this.mergeSuffix = "Merge">
	<cfset this.udfPrefix = "db">
	
	<cfset this.stCommonArgs = {}>
	<cfset this.nIndent = 0>
	<cfset this.bEncrypt = true> 
	<cfset this.sTab = chr( 9 )> 
	<cfset this.sNewLine = chr( 13 ) & chr( 10 )>
	<cfset this.stDefaults = {}>
	
	<cfset this.clearBuffers()>
	
	<cfreturn this>
</cffunction>


<cffunction name="setProperties" output="false">
	<cfset var sKey = "">
	<cfset var fHolder = "">
	
	<cfloop item="sKey" collection="#arguments#">
		<!--- if there is a setter method for this item, pass in the argument to set --->
		<cfif structKeyExists( this, "set" & sKey ) AND isCustomFunction( this[ "set" & sKey ] )>
			<cfset fHolder = this[ "set" & sKey ]>
			<cfset fHolder( arguments[ sKey ] )>
		
		<!--- otherwise just set the property value directly --->
		<cfelse>
			<cfset this[ sKey ] = arguments[ sKey ]>
		</cfif>
	</cfloop>
	
	<cfreturn>
</cffunction>


<cffunction name="setDefaults" output="false">
	<cfset structAppend( this.stDefaults, arguments, true )>
	
	<cfreturn>
</cffunction>


<cfinclude template="sproc-generator/write_definition.cfm">
<cfinclude template="sproc-generator/generate_query_cfc2.cfm">
<cfinclude template="sproc-generator/generate_query_tag2.cfm">


<cfinclude template="sproc-generator/sql_drop_sproc.cfm">
<cfinclude template="sproc-generator/sql_drop_function.cfm">
<cfinclude template="sproc-generator/sql_grant_object2.cfm">
<cfinclude template="sproc-generator/sql_set_options.cfm">


<!-----------------------------------------------------------------------------------------------------------
-- STORED PROCEDURE GENERATION METHODS
------------------------------------------------------------------------------------------------------------>

<cfinclude template="sproc-generator/sproc_count.cfm">
<cfinclude template="sproc-generator/sproc_delete.cfm">
<cfinclude template="sproc-generator/sproc_delete_all.cfm">
<cfinclude template="sproc-generator/sproc_exists.cfm">
<cfinclude template="sproc-generator/sproc_insert.cfm">
<cfinclude template="sproc-generator/sproc_save.cfm">
<cfinclude template="sproc-generator/sproc_select.cfm">
<cfinclude template="sproc-generator/sproc_select_record.cfm">
<cfinclude template="sproc-generator/sproc_select_all.cfm">
<cfinclude template="sproc-generator/sproc_select_set.cfm">
<cfinclude template="sproc-generator/sproc_update.cfm">

<cfinclude template="sproc-generator/sproc_merge.cfm">


<!-----------------------------------------------------------------------------------------------------------
-- METHODS TO APPEND DATA TO THE BUFFER
------------------------------------------------------------------------------------------------------------>


<cffunction name="append" access="package" output="false">
	<cfargument name="sInput" type="string" required="true">
	<cfargument name="bNewLine" type="boolean" default="true">
	<cfargument name="nIndent" type="numeric" default="0">
	
	<!--- adjust indentation --->
	<cfif arguments.nIndent IS NOT 0>
		<cfset this.addIndent( arguments.nIndent )>
	</cfif>
	
	<!--- add a line break --->
	<cfif arguments.bNewLine>
		<cfset arguments.sInput = this.sNewLine & repeatString( this.sTab, this.nIndent ) & arguments.sInput>
	</cfif>
	
	<cfset this.stBuffer[ this.sCurrentBuffer ] = this.stBuffer[ this.sCurrentBuffer ] & arguments.sInput>
	<cfreturn>
</cffunction>

	
<cffunction name="appendOn" access="package" output="false">
	<cfargument name="sInput" type="string" required="true">
	<cfargument name="nIndent" type="numeric" default="0">
	
	<cfset this.append( arguments.sInput, false, arguments.nIndent )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendLine" access="package" output="false">
	<cfargument name="sInput" type="string" required="true">
	<cfargument name="nIndent" type="numeric" default="0">
	
	<cfset this.append( arguments.sInput, true, arguments.nIndent )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendBlank" access="package" output="false">
	<cfset this.append( "" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendTab" access="package" output="false">
	<cfset this.append( this.sTab, false )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendBegin" access="package" output="false">
	<cfset this.append( "BEGIN;" )>
	<cfset this.indent()>
	
	<cfreturn>
</cffunction>


<cffunction name="appendEnd" access="package" output="false">
	<cfset this.unindent()>
	<cfset this.append( "END;" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendHeader" access="package" output="false">
	<!--- add the standard 'header' buffer --->
	<cfset this.addBuffer( "header", "sql", false )>
	
	<cfset this.appendDivide()>
	<cfset this.appendEmptyLine()>
	<cfset this.appendCommentLine( "CODE GENERATED BY GENSPROC ON #dateFormat( now(), 'mm/dd/yyyy' )# AT #timeFormat( now(), 'h:m:ss' )#" )>
	<cfset this.appendEmptyLine()>
	<cfset this.appendDivide()>
	<cfset this.appendBlank()>
	<cfset this.appendBlank()>
	
	<cfreturn>
</cffunction>


<cffunction name="appendDivide" access="package" output="false">
	<cfset this.append( "-- #repeatString( '-', 93 )# --" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendEmptyLine" access="package" output="false">
	<cfset this.append( "-- #repeatString( ' ', 93 )# --" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendCommentLine" access="package" output="false">
	<cfargument name="sInput" type="string" required="true">
	
	<cfset this.append( "-- #lJustify( arguments.sInput, 93 )# --" )>
	<cfreturn>
</cffunction>


<cffunction name="appendComment" access="package" output="false">
	<cfargument name="sInput" type="string" required="true">
	
	<cfset this.append( "-- #arguments.sInput#" )>
	<cfreturn>
</cffunction>


<cffunction name="appendVar">
	<cfargument name="sName" type="string" required="true">
	<cfargument name="sType" type="string" required="true">
	<cfargument name="sDefault" type="string" default="">
	<cfargument name="sComment" type="string" default="">
	
	<!--- prepend variable with a comment for good design --->
	<cfif len( arguments.sComment )>
		<cfset this.appendComment( arguments.sComment )>
	</cfif>
	
	<!--- declare the variable, then set the default value if there is one --->
	<cfset this.append( "DECLARE @#arguments.sName# #uCase( arguments.sType )#;" )>
	<cfif len( arguments.sDefault )>
		<cfif listFindNoCase( "CHAR,VARCHAR,BINARY,VARBINARY,NCHAR,NVARCHAR", arguments.sType )>
			<cfset this.append( "SET @#arguments.sName# = '#arguments.sDefault#';" )>
		<cfelse>
			<cfset this.append( "SET @#arguments.sName# = #arguments.sDefault#;" )>
		</cfif>
	</cfif>
	<cfset this.appendBlank()>
	
	<cfreturn>
</cffunction>


<cffunction name="appendCreateSproc" access="package" output="false">	
	<cfargument name="sSprocName" type="string" required="true">
	
	<cfset this.append( "CREATE PROCEDURE #this.owner#.#this.getSqlSafeName( arguments.sSprocName )#" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendNoCount" access="package" output="false">	
	<cfset this.append( "SET NOCOUNT ON;" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendErrorCheck" access="package" output="false">
	<cfargument name="bTransaction" type="boolean" default="false">
	<cfargument name="sTransactionName" type="string" default="">
	
	<!--- Check if the errorVar is positive, then possibly rollback the transaction --->
	<cfset this.append( "IF( @error != 0 )" )>
	<cfset this.appendBegin()>
	<cfif arguments.bTransaction>
		<cfset this.append( "ROLLBACK TRANSACTION #sTransactionName#;" )>
	</cfif>
	<!--- this is an area that could be extended --->
	<cfset this.customErrorCheck()>
	<cfset this.append( "RETURN 2;" )>
	<cfset this.appendEnd()>
	<!--- if there is no error, but it is a transaction, then commit it --->
	<cfif arguments.bTransaction>
		<cfset this.append( "ELSE" )>
		<cfset this.appendBegin()>
		<cfset this.append( "COMMIT TRANSACTION #sTransactionName#;" )>
		<cfset this.appendEnd()>
	</cfif>
	
	<cfreturn>
</cffunction>


<!--- this method should be extended if you want to provide your own t-sql
code to handle errors if they occur --->
<cffunction name="customErrorCheck" access="package" output="false">
	<cfset this.append( "PRINT 'Put in a custom error handler';" )>
	
	<cfreturn>
</cffunction>


<cffunction name="appendMakeNullFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="bFilterDefaults" type="boolean" default="false">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>		
	<cfset var nState = 10>
	
	<cfquery name="qEmptyFiltered" dbType="query">
		SELECT		*
		FROM		qColumnMetadata
		WHERE		(sTypeName IN ('CHAR','VARCHAR','NCHAR','NVARCHAR'))
		<cfif arguments.bFilterDefaults>
			AND		(sDefaultValue IS NULL)
		</cfif>
	</cfquery>
	
	<!--- check if the data coming in is a string, if it is, trim it, if theres no value, treat it like null --->
	<cfif qEmptyFiltered.recordCount>
		<cfset this.appendComment( "Change empty string values into NULL" )>
		<cfloop query="qEmptyFiltered">
			<cfset this.append( "IF( LTRIM( RTRIM( @#qEmptyFiltered.sColumnName# ) ) = '' )" )>
			<cfset this.appendLine( "SET @#qEmptyFiltered.sColumnName# = NULL", 1 )>
			<cfset this.appendLine( "", -1 )>
		</cfloop>
	</cfif>
	
	<cfreturn>
</cffunction>


<cffunction name="appendCheckFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="bFilterDefaults" type="boolean" default="false">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>		
	<cfset var nState = 10>
	
	<cfquery name="qNullFiltered" dbType="query">
		SELECT		*
		FROM		qColumnMetadata
		WHERE		(isNullable = 0)
			AND		(sTypeName <> 'TIMESTAMP')
		<cfif arguments.bFilterDefaults>
			AND		(sDefaultValue IS NULL)
		</cfif>
	</cfquery>
	
	<cfif qNullFiltered.recordCount>
		<cfset this.appendComment( "Check if all of the params are acceptable" )>
		<cfloop query="qNullFiltered">
			<!--- do an error check that if the value is null throw an error --->
			<cfset this.append( "IF( @#qNullFiltered.sColumnName# IS NULL )" )>
			<cfset this.appendBegin()>
			<cfset this.append( "RAISERROR( 'Param @#qNullFiltered.sColumnName# passed in is invalid', 10, #nState# ) WITH SETERROR" )>
			<cfset this.append( "RETURN @@ERROR" )>
			<cfset this.appendEnd()>
			<cfif currentRow IS NOT qNullFiltered.recordCount>
				<cfset this.appendBlank()>
			</cfif>
			<cfset nState = nState + 1>
		</cfloop>
	</cfif>
	
	<cfreturn>
</cffunction>


<cffunction name="appendParamFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="lOutputFields" type="string" default="">
	<cfargument name="bUseDefaults" type="boolean" default="false">
	<cfargument name="bSearch" type="boolean" default="false">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>
	<cfset var sFieldAdd = " ">
	
	<cfloop query="qColumnMetadata">
		<cfset this.appendLine( "#sFieldAdd##this.sTab##lJustify( '@#qColumnMetadata.sColumnName#', 20 )# #uCase( qColumnMetadata.sTypeName )#" )>
		<cfif qColumnMetadata.nTypeGroup IS 2><!--- decimal, numeric --->
			<cfset this.appendOn( "(#qColumnMetadata.nColumnPrecision#,#qColumnMetadata.nColumnScale#)" )>
		<cfelseif qColumnMetadata.nTypeGroup IS 1><!--- character and binary --->
			<cfset this.appendOn( "(#qColumnMetadata.nColumnLength#)" )>
		</cfif>
		<cfif qColumnMetadata.isNullable OR ( arguments.bUseDefaults AND len( qColumnMetadata.sDefaultValue ) ) OR ( arguments.bSearch AND qColumnMetadata.isSearchable )>
			<cfset this.appendOn( " = NULL" )>
		</cfif>
		<!--- Output column identifier --->
		<cfif listFindNoCase( arguments.lOutputFields, qColumnMetadata.sColumnName )>
			<cfset this.appendOn( " OUTPUT" )>
		</cfif>
		<cfif len( qColumnMetadata.sDefaultValue )>
			<cfset this.appendOn( " -- #replaceNoCase(  qColumnMetadata.sDefaultValue, 'getdate()', 'GETDATE()', 'all' )#" )>
		</cfif>
		<cfset sFieldAdd = ",">
	</cfloop>
	
	<cfreturn>
</cffunction>


<cffunction name="appendSelectFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="bNewLine" type="boolean" default="true">
	<cfargument name="bDoubleTab" type="boolean" default="true">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>
	<cfset var sFieldAdd = "">
	
	<cfif arguments.bNewLine AND arguments.bDoubleTab>
		<cfset sFieldAdd = this.sTab>
	</cfif>
	
	<cfloop query="qColumnMetadata">
		<cfset this.append( sFieldAdd & this.sTab & qColumnMetadata.sColumnNameSafe, arguments.bNewLine )>
		<cfset sFieldAdd = ",">
		<cfif arguments.bDoubleTab>
			<cfset sFieldAdd = sFieldAdd & this.sTab>
		</cfif>
		<cfset arguments.bNewLine = true>
	</cfloop>
	
	<cfreturn>
</cffunction>


<cffunction name="appendValueFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="bUseDefaults" type="boolean" default="false">
	<cfargument name="bNewLine" type="boolean" default="true">
	<cfargument name="bDoubleTab" type="boolean" default="true">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>		
	<cfset var sFieldAdd = "">
	
	<cfif arguments.bDoubleTab>
		<cfset sFieldAdd = this.sTab>
	</cfif>
	
	<cfloop query="qColumnMetadata">
		<cfset this.append( "#sFieldAdd##this.sTab#", arguments.bNewLine )>
		<cfif qColumnMetadata.sTypeName IS "timestamp">
			<cfset this.append( "NULL", false )>
		<cfelseif arguments.bUseDefaults AND len( qColumnMetadata.sDefaultValue )>
			<cfset this.append( "COALESCE( @#qColumnMetadata.sColumnName#, #qColumnMetadata.sDefaultValue# )", false )>
		<cfelse>
			<cfset this.append( "@#qColumnMetadata.sColumnName#", false )>
		</cfif>
		<cfset sFieldAdd = ",">
		<cfif arguments.bDoubleTab>
			<cfset sFieldAdd = sFieldAdd & this.sTab>
		</cfif>
		<cfset arguments.bNewLine = true>
	</cfloop>
	
	<cfreturn>
</cffunction>


<cffunction name="appendUpdateFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="bUseDefaults" type="boolean" default="false">
	<cfargument name="bNewLine" type="boolean" default="true">
	<cfargument name="bDoubleTab" type="boolean" default="true">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>
	<cfset var sFieldAdd = "">
	
	<cfset this.indent()>
		
		<cfloop query="qColumnMetadata">
			<cfset this.append( sFieldAdd & this.sTab & qColumnMetadata.sColumnNameSafe & " = ", arguments.bNewLine )>
			<cfif qColumnMetadata.sTypeName IS "timestamp">
				<cfset this.append( "NULL", false )>
			<cfelseif arguments.bUseDefaults AND len( qColumnMetadata.sDefaultValue )>
				<cfset this.append( "COALESCE( @#qColumnMetadata.sColumnName#, #qColumnMetadata.sDefaultValue# )", false )>
			<cfelse>
				<cfset this.append( "@#qColumnMetadata.sColumnName#", false )>
			</cfif>
			<cfset sFieldAdd = ",">
			<cfif arguments.bDoubleTab>
				<cfset sFieldAdd = sFieldAdd & this.sTab>
			</cfif>
			<cfset arguments.bNewLine = true>
		</cfloop>
	
	<cfset this.unindent()>
	
	<cfreturn>
</cffunction>


<cffunction name="appendWhereFields" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="bSearchFields" type="boolean" default="false">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>
	<cfset var sWhereAdd = "WHERE" & this.sTab>
	<cfset var bNewLine = "">
	
	<cfloop query="qColumnMetadata">
		<cfset this.append( "#sWhereAdd##this.sTab#" )>
		<cfif arguments.bSearchFields>
			<cfif qColumnMetadata.isNullable>
				<cfset this.append( "(COALESCE( #qColumnMetadata.sColumnNameSafe#, '' ) = COALESCE( @#qColumnMetadata.sColumnName#, #qColumnMetadata.sColumnNameSafe#, '' ) )", false )>
			<cfelse>
				<cfset this.append( "(#qColumnMetadata.sColumnNameSafe# = COALESCE( @#qColumnMetadata.sColumnName#, #qColumnMetadata.sColumnNameSafe# ) )", false )>
			</cfif>
		<cfelse>
			<cfset this.append( "(#qColumnMetadata.sColumnNameSafe# = @#qColumnMetadata.sColumnName#)", false )>
		</cfif>
		<cfset sWhereAdd = "#this.sTab#AND#this.sTab#">
	</cfloop>
	
	<cfreturn>
</cffunction>


<cffunction name="appendConditionMatch" access="package" output="false">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumnFilter" type="string" required="true">
	<cfargument name="sColumnPrefix" type="string" default="">
	
	<cfset var qColumnMetadata = this.getColumnMetadata( arguments.qMetadata, arguments.sColumnFilter )>
	<cfset var sAdd = "">
	<cfset var bNewLine = "">
	
	<cfloop query="qColumnMetadata">
		<cfset this.append( "#sAdd##this.sTab#" )>
		<cfset this.append( "(#qColumnMetadata.sColumnNameSafe# = #arguments.sColumnPrefix##qColumnMetadata.sColumnName#)", false )>
		<cfset sAdd = "#this.sTab#AND#this.sTab#">
	</cfloop>
	
	<cfreturn>
</cffunction>



<!-----------------------------------------------------------------------------------------------------------
-- METADATA METHODS
------------------------------------------------------------------------------------------------------------>


<cffunction name="addDefinition" output="true">
	<cfargument name="sType" type="string" required="true">
	<cfargument name="stArgs" type="struct" required="true">
	<cfargument name="sSQL" type="string" required="true">
	
	<cfset var stDef = {}>
	<cfset var stParam = "">
	
	<cfquery name="qPK" dbType="query">
		SELECT		sColumnName
		FROM		stArgs.qFields
		WHERE		(bPrimaryKeyColumn = 1)
	</cfquery>
	
	<cfset stDef.sType = arguments.sType>
	<cfset stDef.stArgs = arguments.stArgs>
	<cfset stDef.stFields = this.getStructMetadata( stArgs.qFields, stArgs.lOutputFields )>
	<!--- <cfset stDef.stParams = this.getStructMetadata( this.filterColumnMetadata( stArgs.qFields, stArgs.lParamFields ), stArgs.lOutputFields )> --->
	<cfset stDef.sSQL = arguments.sSQL>
	<cfset stDef.created = now()>
	
	<cfif NOT structKeyExists( stDef.stArgs, "sDSN" )>
		<cfset stDef.stArgs.sDSN = this.dsn>
	</cfif>
	<cfif NOT structKeyExists( stDef.stArgs, "sQueryName" )>
		<cfset stDef.stArgs.sQueryName = "qSproc_" & replace( arguments.stArgs.sTableName, "_", "", "all" )>
	</cfif>
	<cfif NOT structKeyExists( stDef.stArgs, "lPrimaryKeys" )>
		<cfset stDef.stArgs.lPrimaryKeys = valueList( qPK.sColumnName )>
	</cfif>
	
	<cfset this.stDefinitions[ arguments.stArgs.sSprocName ] = stDef>
	
	<cfreturn>
</cffunction>


<cffunction name="getStructMetadata" output="false" returnType="struct">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="lOutputFields" type="string" default="">
	
	<cfset var stMetadata = {}>
	<cfset var stParam = "">
	<cfloop query="qMetadata">
		<cfset stParam = {}>
		<cfset stParam.type = "in">
		<cfset stParam.varName = "@" & qMetadata.sColumnName>
		<cfset stParam.sqlType = qMetadata.sTypeName>
		<cfset stParam.cfType = this.getCFType( qMetadata.sTypeName )>
		<cfset stParam.cfSQLType = lCase( this.getCFSQLType( qMetadata.sTypeName ) )>
		<!--- Only some default values will work on the CF side --->
		<cfset stParam.default = this.getCFDefaultValue( qMetadata.sDefaultValue )>
		<cfset stParam.index = qMetadata.nColumnID>
		<cfset stParam.scale = qMetadata.nColumnScale>
		<cfset stParam.maxLength = "">
		<cfset stParam.nullable = yesNoFormat( qMetadata.isNullable )>
		<cfset stParam.searchable = yesNoFormat( qMetadata.isSearchable )>
		<cfset stParam.attribs = "">
		<cfif len( qMetadata.sDefaultValue )>
			<cfset stParam.nullable = true>
		</cfif>
		<!--- <cfif qMetadata.isNullable>
			<cfset stParam.attribs = listAppend( stParam.attribs, "nullable" )>
		</cfif> --->
		<cfif qMetadata.isComputed IS 1>
			<cfset stParam.attribs = listAppend( stParam.attribs, "computed" )>
		</cfif>
		<cfif qMetadata.isIdentity IS 1>
			<cfset stParam.attribs = listAppend( stParam.attribs, "identity" )>
		</cfif>
		<cfif qMetadata.bPrimaryKeyColumn IS 1>
			<cfset stParam.attribs = listAppend( stParam.attribs, "primarykey" )>
		</cfif>
		<cfif listFindNoCase( arguments.lOutputFields, qMetadata.sColumnName )>
			<cfset stParam.type = "out">
		</cfif>
		<cfif listFindNoCase( "char,nchar,varchar,nvarchar", qMetadata.sTypeName )>
			<cfset stParam.maxLength = qMetadata.nColumnPrecision>
		</cfif>
		<cfset stMetadata[ qMetadata.sColumnName ] = stParam>
	</cfloop>

	<cfreturn stMetadata>
</cffunction>


<cffunction name="getBlankColumnMetadata" access="package" output="false" returnType="query">
	<cfreturn queryNew( "sColumnName,nColumnID,bPrimaryKeyColumn,nTypeGroup,nColumnLength,nColumnPrecision,nColumnScale,isNullable,isIdentity,sTypeName,sDefaultValue" )>
</cffunction>


<cffunction name="addColumnMetadataRow" access="package" output="false" returnType="query">
	<cfargument name="qMetadata" type="query" default="#this.getBlankColumnMetadata()#">
	
	<cfset var key = "">
	
	<cfset queryAddRow( arguments.qMetadata, 1 )>
	
	<cfif structKeyExists( arguments, "sTypeName" )>
		<cfswitch expression="#arguments.sTypeName#">
			<cfcase value="INT">
				<cfset arguments.nTypeGroup = 0>
				<cfset arguments.nColumnLength = 4>
				<cfset arguments.nColumnPrecision = 10>
				<cfset arguments.nColumnScale = 0>
			</cfcase>
		</cfswitch>
		<cfif NOT structKeyExists( arguments, "isSearchable" )>
			<cfset arguments.isSearchable = this.isSearchableType( arguments.sTypeName )>
		</cfif>
	</cfif>
	
	<cfloop index="key" list="#arguments.qMetadata.columnList#">
		<cfif structKeyExists( arguments, key )>
			<cfset arguments.qMetadata.key[ arguments.qMetadata.recordCount ] = arguments[ key ]>
		<cfelse>
			<cfset arguments.qMetadata.key[ arguments.qMetadata.recordCount ] = "">
		</cfif>
	</cfloop>
	
	<cfset arguments.qMetadata.nColumnID[ arguments.qMetadata.recordCount ] = arguments.qMetadata.recordCount>
	
	<cfreturn arguments.qMetadata>
</cffunction>


<cffunction name="getTableMetadata" access="package" output="false" returnType="query">
	<cfargument name="sTableName" type="string" required="true">
	
	<cfquery name="qMetadata" dataSource="#this.dsn#">
		SELECT		nColumnID
				,	sColumnName
				,	bPrimaryKeyColumn
				,	nTypeGroup
				,	nColumnLength
				,	nColumnPrecision
				,	nColumnScale
				,	isNullable
				,	isComputed
				,	isIdentity
				,	isSearchable
				,	sTypeName
				,	sDefaultValue
				<!--- extra crap --->
				<!--- ,	'in' AS [type] --->
				<!--- ,	'@' + sColumnName AS [varName] --->
				,	sColumnName AS [sColumnNameSafe]
				,	sColumnName AS [fieldName]
				,	sTypeName AS [sqlType]
				,	sTypeName AS [cfType]
				,	sTypeName AS [cfSQLType]
				,	'' AS [default]
				,	nColumnID AS [index]
				,	nColumnScale AS [scale]
				,	0 AS [maxLength]
				,	isNullable AS [nullable]
				,	isSearchable AS [searchable]
				,	'' AS [attribs]
		FROM		dbo.udf_getTableColumnInfo2( '#arguments.sTableName#' )
		ORDER BY	1
	</cfquery>
	
	<cfloop query="qMetadata">
		<cfset qMetadata.sColumnNameSafe[ currentRow ] = this.getSqlSafeName( qMetadata.sColumnName )>
		<cfset qMetadata.fieldName[ currentRow ] = this.camelCase( qMetadata.fieldName )>
		<cfset qMetadata.cfType[ currentRow ] = this.getCFType( qMetadata.cfType )>
		<cfset qMetadata.cfSQLType[ currentRow ] = lCase( this.getCFSQLType( qMetadata.cfSQLType ) )>
		<cfset qMetadata.nullable[ currentRow ] = yesNoFormat( qMetadata.isNullable )>
		<cfset qMetadata.searchable[ currentRow ] = yesNoFormat( qMetadata.isSearchable )>
		<cfif len( qMetadata.sDefaultValue )>
			<cfset qMetadata.nullable[ currentRow ] = true>
			<cfset qMetadata.isNullable[ currentRow ] = true>
		</cfif>
		<!--- <cfif qMetadata.isNullable>
			<cfset qMetadata.attribs[ currentRow ] = listAppend( qMetadata.attribs, "nullable" )>
		</cfif> --->
		<cfif qMetadata.isComputed IS 1>
			<cfset qMetadata.attribs[ currentRow ] = listAppend( qMetadata.attribs, "computed" )>
		</cfif>
		<cfif qMetadata.isIdentity IS 1>
			<cfset qMetadata.attribs[ currentRow ] = listAppend( qMetadata.attribs, "identity" )>
		</cfif>
		<cfif qMetadata.bPrimaryKeyColumn IS 1>
			<cfset qMetadata.attribs[ currentRow ] = listAppend( qMetadata.attribs, "primarykey" )>
		</cfif>
		<cfif listFindNoCase( "char,nchar,varchar,nvarchar", qMetadata.sTypeName )>
			<cfset qMetadata.maxLength[ currentRow ] = qMetadata.nColumnLength>
		</cfif>
	</cfloop>
	
	<cfreturn qMetadata>
</cffunction>


<cffunction name="getColumnMetadata" access="package" output="false" returnType="query">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sColumns" type="string" required="true">
	
	<cfquery name="qColumnMetadata" dbType="query">
		SELECT		*
		FROM		qMetadata
		WHERE		(0=0)
		<cfif len( arguments.sColumns )>
			AND		(sColumnName IN (<cfqueryparam value="#arguments.sColumns#" cfsqltype="varchar" list="true" separator=",">))
		<cfelse>
			AND		(0=1)
		</cfif>			
	</cfquery>
	
	<cfreturn qColumnMetadata>
</cffunction>


<cffunction name="filterColumnMetadata" access="package" output="false" returnType="query">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sFilter" type="string" default="*">
	
	<cfset var bKeyFilter = false>
	<cfset var bNullFilter = "">
	<cfset var bLikeableFilter = false>
	<cfset var bComputedFilter = false>
	<cfset var bCompareFilter = false>
	<cfset var sField = "">
	<cfset var sIncludeFields = "">
	<cfset var sExcludeFields = "">
	
	<cfloop index="sField" list="#arguments.sFilter#" delimiters=",">
		<cfif sField IS "!PK">
			<cfset bKeyFilter = true>
		<cfelseif sField IS "!MUTABLE" OR sField IS "+">
			<cfset bComputedFilter = true>
		<cfelseif sField IS "!COMPARABLE">
			<cfset bCompareFilter = true>
		<cfelseif sField IS "!NULL">
			<cfset bNullFilter = 1>
		<cfelseif sField IS "!NOTNULL">
			<cfset bNullFilter = 0>
		<cfelseif sField IS "!LIKEABLE">
			<cfset bLikeableFilter = true>
		<cfelseif sField IS NOT "*">
			<cfif left( sField, 1 ) IS "-">
				<cfset sExcludeFields = listAppend( sExcludeFields, right( sField, len( sField ) - 1 ), "," )>
			<cfelse>
				<cfset sIncludeFields = listAppend( sIncludeFields, sField, "," )>
			</cfif>
		</cfif>
	</cfloop>
	
	<cfquery name="qFilteredColumnMetadata" dbType="query">
		SELECT		*
		FROM		qMetadata
		WHERE		(0 = 0)
		<cfif bKeyFilter>
			AND		(bPrimaryKeyColumn = 1)
		<cfelseif bComputedFilter>
			AND		(isComputed = 0)
			AND		(isIdentity = 0)
		</cfif>
		<cfif bCompareFilter>
			AND		(sTypeName NOT IN ('text','ntext','image','binary','varbinary'))
		</cfif>
		<cfif bLikeableFilter>
			AND		(sTypeName IN ('char','varchar','text','nchar','nvarchar','ntext'))
		</cfif>
		<cfif len( bNullFilter )>
			AND		(isNullable = #bNullFilter#)
		</cfif>
		<cfif arguments.sFilter IS "-">
			AND		(0 = 1)
		<cfelseif len( sIncludeFields )>
			AND		(sColumnName IN (<cfqueryparam value="#sIncludeFields#" cfsqltype="varchar" list="true" separator=",">))
		<cfelseif len( sExcludeFields )>
			AND		(sColumnName NOT IN (<cfqueryparam value="#sExcludeFields#" cfsqltype="varchar" list="true" separator=",">))
		</cfif>
	</cfquery>
	
	<cfreturn qFilteredColumnMetadata>
</cffunction>


<cffunction name="filterColumnList" access="package" output="false" returnType="string">
	<cfargument name="qMetadata" type="query" required="true">
	<cfargument name="sFilter" type="string" default="*">
	
	<cfset var bPKFilter = false>
	<cfset var bNullFilter = "">
	<cfset var bLikeableFilter = false>
	<cfset var bComputedFilter = false>
	<cfset var bCompareFilter = false>
	<cfset var sField = "">
	<cfset var sIncludeFields = "">
	<cfset var sExcludeFields = "">
	
	<!--- don't select any fields --->
	<cfif NOT len( arguments.sFilter ) OR arguments.sFilter IS "-">
		<cfset arguments.sFilter = "-">
	<cfelse>
		<cfloop index="sField" list="#arguments.sFilter#" delimiters=",">
			<cfif sField IS "!PK">
				<!--- only select primary key columns --->
				<cfset bPKFilter = true>
			<cfelseif sField IS "!MUTABLE" OR sField IS "+">
				<!--- exclude computed and identity fields --->
				<cfset bComputedFilter = true>
			<cfelseif sField IS "!COMPARABLE">
				<cfset bCompareFilter = true>
			<cfelseif sField IS "!NULL">
				<cfset bNullFilter = 1>
			<cfelseif sField IS "!NOTNULL">
				<cfset bNullFilter = 0>
			<cfelseif sField IS "!LIKEABLE">
				<cfset bLikeableFilter = true>
			<cfelseif NOT sField IS "*">
				<cfif left( sField, 1 ) IS "-">
					<cfset sExcludeFields = listAppend( sExcludeFields, right( sField, len( sField ) - 1 ), "," )>
				<cfelse>
					<cfset sIncludeFields = listAppend( sIncludeFields, sField, "," )>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	
	<cfquery name="qFilteredList" dbType="query">
		SELECT		sColumnName
		FROM		qMetadata
		WHERE		(0 = 0)
		<cfif bPKFilter>
			AND		(bPrimaryKeyColumn = 1)
		<cfelseif bComputedFilter>
			AND		(isComputed = 0)
			AND		(isIdentity = 0)
		</cfif>
		<cfif bCompareFilter>
			AND		(sTypeName NOT IN ('text','ntext','image','binary','varbinary'))
		</cfif>
		<cfif bLikeableFilter>
			AND		(sTypeName IN ('char','varchar','text','nchar','nvarchar','ntext'))
		</cfif>
		<cfif len( bNullFilter )>
			AND		(isNullable = #bNullFilter#)
		</cfif>
		<cfif arguments.sFilter IS "-">
			AND		(0 = 1)
		<cfelseif len( sIncludeFields )>
			AND		(sColumnName IN (<cfqueryparam value="#sIncludeFields#" cfsqltype="varchar" list="true" separator=",">))
		<cfelseif len( sExcludeFields )>
			AND		(sColumnName NOT IN (<cfqueryparam value="#sExcludeFields#" cfsqltype="varchar" list="true" separator=",">))
		</cfif>
	</cfquery>
	
	<cfreturn udf.listSortByListNoCase( valueList( qFilteredList.sColumnName ), sIncludeFields )>
</cffunction>

	
<!-----------------------------------------------------------------------------------------------------------
-- METHODS TO CONTROL AND MANAGE THE BUFFER
------------------------------------------------------------------------------------------------------------>


<cffunction name="indent" access="package" output="false" hint="Increase the indentation by 1">
	<cfset this.nIndent = this.nIndent + 1>
	<cfreturn>
</cffunction>


<cffunction name="unindent" access="package" output="false" hint="Decrease the indentation by 1">
	<cfset this.nIndent = max( 0, this.nIndent - 1 )>
	<cfreturn>	
</cffunction>


<cffunction name="addIndent" access="package" output="false" hint="Change the level of indentation">
	<cfargument name="indent" type="numeric" required="true">
	<cfset this.nIndent = max( 0, this.nIndent + arguments.indent )>
	<cfreturn>
</cffunction>


<cffunction name="resetIndent" access="package" output="false" hint="Reset the level of indentation to zero">
	<cfset this.nIndent = 0>
	<cfreturn>
</cffunction>


<cffunction name="clearBuffers" output="false">
	
	<!--- clear the buffers --->
	<cfset this.lBufferOrder = "">
	<cfset this.stBuffer = {}>
	<cfset this.stBufferType = {}>
	<cfset this.stDefinitions = {}>
	
	<!--- add the standard 'header' buffers --->
	<cfset this.appendHeader()>
	
	<cfreturn>
</cffunction>


<cffunction name="addBuffer" access="package" output="false">
	<cfargument name="sBufferKey" type="string" required="true">
	<cfargument name="sBufferType" type="string" default="sql">
	<cfargument name="bAddFinish" type="boolean" default="false">
	
	<!--- add a bunch of line breaks to the end of the file --->
	<cfif arguments.bAddFinish AND len( this.sCurrentBuffer )>
		<cfset this.appendBlank()>
		<cfset this.appendDivide()>
		<cfset this.appendBlank()>
		<cfset this.appendBlank()>
	</cfif>
	
	<!--- check that the key doesn't exist already --->
	<cfif structKeyExists( this.stBuffer, arguments.sBufferKey )>
		<cfthrow
			type="Custom.CFC.BufferAlreadyExists"
			message="Buffer referenced by key ""#arguments.sBufferKey#"" already exists."
		>
	</cfif>
	
	<!--- add an empty buffer --->
	<cfset this.stBuffer[ arguments.sBufferKey ] = "">
	
	<!--- save the buffer type --->
	<cfset this.stBufferType[ arguments.sBufferKey ] = arguments.sBufferType>
	
	<!--- save the buffer order --->
	<cfset this.lBufferOrder = listAppend( this.lBufferOrder, arguments.sBufferKey )>
	
	<!--- mark the buffer as 'current' --->
	<cfset this.sCurrentBuffer = arguments.sBufferKey>
	
	<cfreturn>
</cffunction>


<cffunction name="readBuffer" output="false" returnType="string">
	<cfargument name="sBufferKey" type="string" default="*">
	<cfargument name="sBufferType" type="string" default="*"><!--- *, sql or cfm --->
	
	<cfset var sOutput = "">
	<cfset var sItem = "">
	
	<cfif arguments.sBufferKey IS "*">
		<cfset arguments.sBufferKey = this.lBufferOrder>
	<cfelse>
		<cfset arguments.sBufferType = "*">
	</cfif>
	
	<!--- read only the buffer specified "*", "sql" or "cfm" --->
	<cfloop index="sItem" list="#arguments.sBufferKey#">
		<cfif arguments.sBufferType IS "*" OR this.stBufferType[ sItem ] IS arguments.sBufferType>
			<cfset sOutput = sOutput & this.stBuffer[ sItem ] & this.sNewLine>
		</cfif>
	</cfloop>
	
	<cfreturn trim( sOutput )>
</cffunction>


<cffunction name="writeIfDifferent" output="false">
	<cfargument name="sFileName" type="string" required="true">
	<cfargument name="sContent" type="string" required="true">
	
	<cfset var bWrite = true>
	
	<cfif fileExists( sFileName )>
		<cffile
			action="read"
			file="#local.sFileName#"
			variable="local.sOldContent"
		>
		<cfif compare( arguments.sContent, local.sOldContent ) IS 0>
			<cfset bWrite = false>
		</cfif>
	</cfif>
	
	<cfif bWrite>
		<cffile
			action="write"
			file="#arguments.sFileName#"
			output="#arguments.sContent#"
		>
	</cfif>
	
	<cfreturn>		
</cffunction>


<cffunction name="writeBuffer" output="false">
	<cfargument name="sFileName" type="string" required="true">
	<cfargument name="sBufferKey" type="string" default="*">
	<cfargument name="sBufferType" type="string" default="sql"><!--- *, sql or cfm --->
	<cfargument name="bGroup" type="boolean" default="false">
	<cfset var sItem = "">
	
	<cfif arguments.bGroup>
		<!--- write a group of files for each buffer --->
		<cfloop index="sItem" list="#this.lBufferOrder#">
			<cfset this.writeIfDifferent( replace( arguments.sFileName, "##", "_" & sItem ), this.readBuffer( sItem, arguments.sBufferType ) )>
		</cfloop>
	<cfelse>
		<!--- write a single file for all of the buffers --->
		<cfset this.writeIfDifferent( arguments.sFileName, this.readBuffer( arguments.sBufferKey, arguments.sBufferType ) )>
	</cfif>
	
	<cfreturn>
</cffunction>


<cffunction name="executeBuffer" output="true">
	<cfargument name="sBufferKey" type="string" default="*">
	
	<cfset var sBatch = "">
	<cfset var nLast = 1>
	<cfset var bError = false>
	<cfset var stError = "">
	<cfset var sFullBuffer = "">
	<cfset var nFound = "">
	
	<!--- DSN is required to execute --->
	<cfif NOT len( this.dsn )>
		<cfthrow
			type="Custom.CFC.MissingDSN"
			message="DSN must be set to execute sql code."
		>
	</cfif>
	
	<!--- Run in a transaction so it can be rolled back if there is an error --->
	<!--- <cftransaction action="begin"> --->
		<!--- grab all of the sql buffer content --->
		<cfset sFullBuffer = this.readBuffer( arguments.sBufferKey, "sql" )>
		<!--- begin finding batches --->
		<cfset nFound = reFindNoCase( this.sNewLine & "GO" & this.sNewLine, sFullBuffer, 1, false )>
		
		<cfloop condition="nFound IS NOT 0 AND NOT bError">
			<!--- each batch is the code between the "GO" statements --->
			<cfset sBatch = mid( sFullBuffer, nLast, ( nFound - nLast ) )>
			
			<cftry>
				<cfquery name="qExecute" dataSource="#this.dsn#">
					#preserveSingleQuotes( sBatch )#
				</cfquery>
				<cfcatch type="any">
					<cfset bError = true>
					<cfset stError = cfcatch>
					<cfoutput>
						#htmlCodeFormat( preserveSingleQuotes( sBatch ) )#						
						<b>ERROR</b><br />
						#cfcatch.type#<br />
						#cfcatch.message#<br />
						#cfcatch.detail#<br />
						<cfdump var="#cfcatch#">
					</cfoutput>
					<!--- <cfbreak> --->
				</cfcatch>
			</cftry>
			
			<!--- find the next batch --->
			<cfset nLast = nFound + len( this.sNewLine ) + 2 + len( this.sNewLine )>
			<cfset nFound = reFindNoCase( this.sNewLine & "GO", sFullBuffer, nLast, false )>
		</cfloop>
		
		<!--- commit if everything worked --->
		<!--- <cfif bError>
			<cftransaction action="rollback">
		</cfif>
	</cftransaction>
	--->
	
	<cfreturn>
</cffunction>


<cffunction name="outputBuffer" output="true">
	<cfoutput>#this.readBuffer( "*", "*" )#</cfoutput>
	<cfreturn>
</cffunction>




<!-----------------------------------------------------------------------------------------------------------
-- MISC
------------------------------------------------------------------------------------------------------------>


<cffunction name="installUDFs" output="false">

	<cfset var sCode = "">
	
	<cfset this.resetIndent()>
	<cfset this.addBuffer( "sql_install_udfs", "sql", true )>
	
	<cfsavecontent variable="sCode"><cfoutput><cfinclude template="sproc-generator/install_udfs.sql"></cfoutput></cfsavecontent>
	
	<cfset this.append( sCode, false )>
	
	<cfreturn>
</cffunction>


<cffunction name="getCFDefaultValue" output="false" returnType="string">
	<cfargument name="sValue" type="string" required="true">
	
	<cfreturn "">
	
	<cfif left( arguments.sValue, 1 ) IS "'" AND right( arguments.sValue, 1 ) IS "'">
		<cfset arguments.sValue = mid( arguments.sValue, 2, len( arguments.sValue ) - 2 )>
	</cfif>
	
	<cfif arguments.sValue IS "GETDATE()">
		<cfreturn "##now()##">
	<cfelseif reFind( "(\[\]\(\)\@\+\*%/)", arguments.sValue )>
		<cfreturn "">
	<cfelseif isNumeric( arguments.sValue )>
		<cfreturn arguments.sValue>
	<cfelseif isBoolean( arguments.sValue )>
		<cfreturn arguments.sValue>
	</cfif>
	
	<cfreturn "">
</cffunction>


<cffunction name="getCFType" output="false" returnType="string">
	<cfargument name="sType" type="string" required="true">
	
	<cfswitch expression="#arguments.sType#">
		<cfcase value="CHAR,VARCHAR,TEXT,NCHAR,NVARCHAR,NTEXT,UNIQUEIDENTIFIER">
			<cfreturn "string">
		</cfcase>
		<cfcase value="BIT">
			<cfreturn "boolean">
		</cfcase>
		<cfcase value="BIGINT,INT,SMALLINT,TINYINT,DECIMAL,NUMERIC,MONEY,SMALLMONEY,FLOAT,REAL">
			<cfreturn "numeric">
		</cfcase>
		<cfcase value="DATETIME,SMALLDATETIME">
			<cfreturn "date">
		</cfcase>
		<cfcase value="BINARY,VARBINARY,IMAGE">
			<cfreturn "binary">
		</cfcase>
	</cfswitch>
	
	<cfreturn "any">
</cffunction>


<cffunction name="getCFSQLType" output="false" returnType="string">
	<cfargument name="sType" type="string" required="true">

	<cfswitch expression="#arguments.sType#">
		<cfcase value="VARCHAR,NVARCHAR">
			<cfreturn "VARCHAR">
		</cfcase>
		<cfcase value="CHAR,NCHAR">
			<cfreturn "CHAR">
		</cfcase>
		<cfcase value="TEXT,NTEXT,XML">
			<cfreturn "LONGVARCHAR">
		</cfcase>
		<cfcase value="INT">
			<cfreturn "INTEGER">
		</cfcase>
		<cfcase value="BIGINT">
			<cfreturn "BIGINT">
		</cfcase>
		<cfcase value="TINYINT">
			<cfreturn "TINYINT">
		</cfcase>
		<cfcase value="SMALLINT">
			<cfreturn "SMALLINT">
		</cfcase>
		<cfcase value="BIT">
			<cfreturn "BIT">
		</cfcase>
		<cfcase value="MONEY,SMALLMONEY">
			<cfreturn "MONEY">
			<!--- <cfreturn "MONEY4"> --->
		</cfcase>
		<cfcase value="DATETIME,SMALLDATETIME,TIMESTAMP">
			<cfreturn "TIMESTAMP">
		</cfcase>
		<cfcase value="DATE">
			<cfreturn "DATE">
		</cfcase>
		<cfcase value="TIME">
			<cfreturn "TIME">
		</cfcase>
		<cfcase value="DOUBLE">
			<cfreturn "DOUBLE">
		</cfcase>
		<cfcase value="REAL">
			<cfreturn "REAL">
		</cfcase>
		<cfcase value="FLOAT">
			<cfreturn "FLOAT">
		</cfcase>
		<cfcase value="DECIMAL">
			<cfreturn "DECIMAL">
		</cfcase>
		<cfcase value="NUMERIC">
			<cfreturn "NUMERIC">
		</cfcase>
		<cfcase value="BINARY">
			<cfreturn "BLOB">
		</cfcase>
		<cfcase value="VARBINARY">
			<cfreturn "VARBINARY" />
		</cfcase>
		<cfcase value="IMAGE">
			<cfreturn "LONGVARBINARY" />
		</cfcase>
		<cfcase value="UNIQUEIDENTIFIER">
			<cfreturn "CHAR" />
		</cfcase>
		<!--- <cfdefaultcase>
			<cfreturn uCase( "#arguments.sType#" )>
		</cfdefaultcase> --->
	</cfswitch>
	
	<cfreturn "">
</cffunction>


<cffunction name="isSearchableType" output="false" returnType="string">
	<cfargument name="sType" type="string" required="true">
	
	<cfif listFindNoCase( "TEXT,NTEXT,TIMESTAMP,BINARY,VARBINARY,IMAGE", sType )>
		<cfreturn false>
	</cfif>
	
	<cfreturn true>
</cffunction>


<cffunction name="getSqlSafeName" output="false" returntype="string">
	<cfargument name="sInput" type="string" required="true">
	
	<cfif listFindNoCase( "ADD,EXCEPT,PERCENT,ALL,EXEC,PLAN,ALTER,EXECUTE,PRECISION,AND,EXISTS,PRIMARY,ANY,EXIT,PRINT,AS,"
				& "FETCH,PROC,ASC,FILE,PROCEDURE,AUTHORIZATION,FILLFACTOR,PUBLIC,BACKUP,FOR,RAISERROR,BEGIN,FOREIGN,READ,"
				& "BETWEEN,FREETEXT,READTEXT,BREAK,FREETEXTTABLE,RECONFIGURE,BROWSE,FROM,REFERENCES,BULK,FULL,REPLICATION,"
				& "BY,FUNCTION,RESTORE,CASCADE,GOTO,RESTRICT,CASE,GRANT,RETURN,CHECK,GROUP,REVOKE,CHECKPOINT,HAVING,RIGHT,"
				& "CLOSE,HOLDLOCK,ROLLBACK,CLUSTERED,IDENTITY,ROWCOUNT,COALESCE,IDENTITY_INSERT,ROWGUIDCOL,COLLATE,IDENTITYCOL,"
				& "RULE,COLUMN,IF,SAVE,COMMIT,IN,SCHEMA,COMPUTE,INDEX,SELECT,CONSTRAINT,INNER,SESSION_USER,CONTAINS,INSERT,"
				& "SET,CONTAINSTABLE,INTERSECT,SETUSER,CONTINUE,INTO,SHUTDOWN,CONVERT,IS,SOME,CREATE,JOIN,STATISTICS,CROSS,"
				& "KEY,SYSTEM_USER,CURRENT,KILL,TABLE,CURRENT_DATE,LEFT,TEXTSIZE,CURRENT_TIME,LIKE,THEN,CURRENT_TIMESTAMP,"
				& "LINENO,TO,CURRENT_USER,LOAD,TOP,CURSOR,NATIONAL,TRAN,DATABASE,NOCHECK,TRANSACTION,DBCC,NONCLUSTERED,TRIGGER,"
				& "DEALLOCATE,NOT,TRUNCATE,DECLARE,NULL,TSEQUAL,DEFAULT,NULLIF,UNION,DELETE,OF,UNIQUE,DENY,OFF,UPDATE,DESC,"
				& "OFFSETS,UPDATETEXT,DISK,ON,USE,DISTINCT,OPEN,USER,DISTRIBUTED,OPENDATASOURCE,VALUES,DOUBLE,OPENQUERY,"
				& "VARYING,DROP,OPENROWSET,VIEW,DUMMY,OPENXML,WAITFOR,DUMP,OPTION,WHEN,ELSE,OR,WHERE,END,ORDER,WHILE,ERRLVL,"
				& "OUTER,WITH,ESCAPE,OVER,WRITETEXT", sInput )>
		<cfreturn "[" & sInput & "]">	
	</cfif>
	
	<cfreturn sInput>
</cffunction>


<cffunction name="camelCase" output="false" returntype="string">
	<cfargument name="sInput" type="string" required="true">
	<cfargument name="sDelim" type="string" default="_">
	
		<cfset var sOutput = "">
	<cfset var word = "">
	<cfset var i = 1>
	<cfset var strlen = listLen( sInput, sDelim )>
	
	<cfif NOT len( sInput )>
		<cfreturn "">
	</cfif>
	
	<cfscript>
		for( i=1; i LTE strlen; i=i+1 ) {
			word = listGetAt( sInput, i, sDelim );
			sOutput &= uCase( left( word, 1 ) );
			if( len( word ) GT 1 ) sOutput &= right( word, len( word ) - 1 );
			// if( i LT strlen ) sOutput = sOutput;
		}
	</cfscript>
	
	<!--- <cfset request.log( "!!CAMEL: #sInput# = #sOutput#" )> --->
	
	<!--- camel-case the first letter --->
	<cfset sOutput = lCase( left( sOutput, 1 ) ) & replaceList( right( sOutput, len( sOutput ) - 1 ), "Id,Pk,Fk,Ukey,Rkey", "ID,PK,FK,UKey,RKey" )>
	
	<cfreturn sOutput>
</cffunction>
	
	
</cfcomponent>