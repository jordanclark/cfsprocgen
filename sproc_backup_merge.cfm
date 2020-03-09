
<cffunction name="backupMergeSproc" output="false">

<cfargument name="sBackupName" type="string" default="backup">
<cfargument name="sTableName" type="string" required="true">
<cfargument name="bAllowDelete" type="boolean" default="true">
<cfargument name="bOutput" type="boolean" default="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.backupMergeSuffix#">
<cfargument name="lAllFields" type="string" default="!COMPUTED">
<cfargument name="lPKField" type="string" default="!PK">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName, "*" )>
<cfset var sTransName = left( replaceNoCase( replace( arguments.sSprocName, "_", "", "all" ), "gsp", "tran_" ), 32 )>
<cfset var bIdentityField = ( listFind( valueList( qMetadata.isIdentity ), 1 ) ? true : false )>
<cfset var sWhereAppend = "">
<cfset var sUpdateAppend = "">

<cfset structAppend( arguments, this.stDefaults, false )>

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lUpdateFields = this.filterColumnList( qMetadata, listAppend( arguments.lAllFields, "!MUTABLE" ) )>
<cfset arguments.lAllFields = this.filterColumnList( qMetadata, arguments.lAllFields )>
<cfset arguments.lPKField = this.filterColumnList( qMetadata, arguments.lPKField )>
<cfset arguments.lParamFields = "">
<cfset arguments.lInputFields = "">
<cfset arguments.lOutputFields = "">
<cfset var qColumnMetadata = this.getColumnMetadata( qMetadata, arguments.lUpdateFields )>

<cfif NOT listLen( arguments.lAllFields )>
	<cfset request.log( qMetadata )>
	<cfset request.log( sTransName )>
	<cfset request.log( arguments )>
	<cfset request.log( "!!Error: No fields to merge. [MergeSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.MergeSproc.NoFields"
		message="No fields to merge."
	>
</cfif>

<!--- New buffer for sproc --->
<cfset this.addBuffer( arguments.sSprocName, "sql", true )>

<!--- Remove an existing sproc --->
<cfset this.appendDropSproc( arguments.sSprocName )>
<cfset this.appendSetOptions()>

<!--- Here is the meat and bones of it all --->
<cfset this.appendCreateSproc( arguments.sSprocName )>
<!--- <cfset this.appendParamFields( qMetadata, arguments.lParamFields, arguments.lOutputFields, false )> --->
<cfset this.append( "AS" )>
<cfset this.appendBegin()>
	<!--- <cfset this.appendNoCount()> --->
	
	<cfset this.appendVar( "error", "int", "0", "Add a safe place to hold errors" )>
	<cfset this.appendVar( "rowcount", "int", "0", "Count the number of rows updated" )>
		
	<cfif bIdentityField>
		<cfset this.append( "BEGIN TRANSACTION #sTransName#;" )>
		<cfset this.append( "SET IDENTITY_INSERT #sBackupName#.#this.owner#.#this.getSqlSafeName( arguments.sTableName )# ON;" )>
		<cfset this.appendBlank()>
		<cfset this.indent()>
	</cfif>

	<cfset this.append( "MERGE INTO #sBackupName#.#this.owner#.#this.getSqlSafeName( arguments.sTableName )# AS t" )>
	<cfset this.append( "USING #this.owner#.#this.getSqlSafeName( arguments.sTableName )# AS s" )>
	<cfset this.append( "ON (" )>
	<cfloop index="f" list="#arguments.lPKField#">
		<cfset this.append( sWhereAppend & "t.#f# = s.#f#", false )>
		<cfset sWhereAppend = " AND ">
	</cfloop>
	<cfset this.append( ")", false )>
	<cfset this.append( "WHEN MATCHED AND EXISTS( SELECT s.* EXCEPT SELECT t.* )" )>
	<!--- <cfset this.append( "WHEN MATCHED" )> --->
	<!--- UPDATE --->
	<cfset this.indent()>
	<cfset this.append( this.sTab & "THEN UPDATE SET" )>
	<cfloop query="qColumnMetadata">
		<cfset this.append( sUpdateAppend & this.sTab & "t." & qColumnMetadata.sColumnNameSafe & " = s." & qColumnMetadata.sColumnNameSafe, true )>
		<cfset sUpdateAppend = ",">
	</cfloop>	
	<cfset this.unindent()>
	<!--- /UPDATE --->
	<cfset this.append( "WHEN NOT MATCHED BY TARGET" )>
	<!--- INSERT --->
	<cfset this.indent()>
	<cfset this.append( this.sTab & "THEN INSERT (" )>
	<cfset this.appendSelectFields( qMetadata, arguments.lAllFields, false, false )>
	<cfset this.append( ")" )>
	<cfset this.append( "VALUES (" )>
	<cfset this.appendSelectFields( qMetadata, arguments.lAllFields, false, false, "s." )>
	<cfset this.append( ")" )>
	<cfset this.unindent()>
	<!--- /INSERT --->
	<cfif arguments.bAllowDelete>
		<cfset this.append( "WHEN NOT MATCHED BY SOURCE" )>
		<cfset this.append( this.sTab & "THEN DELETE" )>
	</cfif>

	

	<cfset this.append( "OUTPUT $action, INSERTED." & replace( arguments.lPKField, ',', ', INSERTED.', 'all' ) & ", DELETED." & replace( arguments.lPKField, ',', ', DELETED.', 'all' ) )>
	<cfset this.append( ";" )>
	<cfset this.appendBlank()>
	<cfset this.append( "SELECT" )>
	<cfset this.append( this.sTab & "" & this.sTab & "@error = @@ERROR" )>
	<cfset this.append( this.sTab & "," & this.sTab & "@rowcount = @@ROWCOUNT" )>
	<cfset this.append( this.sTab & ";" )>
	
	<cfset this.appendBlank()>
	<cfset this.append( "PRINT '#sBackupName#.#this.owner#.#this.getSqlSafeName( arguments.sTableName )# Merge ' + CONVERT( VARCHAR(7), @rowcount ) + ' rows';" )>
	<cfset this.append( "IF( @error != 0 ) PRINT 'Error: ' + CONVERT( VARCHAR(7), @error );" )>
	<cfif bIdentityField>
		<cfset this.unindent()>
		<cfset this.appendComment( "Check the transaction for errors and commit or rollback" )>
	</cfif>
	
	<!--- only manage transaction if inserting into identity table --->
	<cfif bIdentityField>
		<cfset this.appendErrorCheck( true, sTransName )>
		<cfset this.appendBlank()>
		<cfset this.append( "SET IDENTITY_INSERT #sBackupName#.#this.owner#.#this.getSqlSafeName( arguments.sTableName )# OFF;" )>
	</cfif>
	
	<cfset this.append( "RETURN 0;" )>

<cfset this.appendEnd()>
<cfset this.append( "GO" )>
<cfset this.appendBlank()>
<cfset this.appendGrantObject( arguments.sSprocName, arguments.lUsersPermitted )>

<cfset arguments.qFields = qMetadata>
<!--- <cfset arguments.lInputFields = udf.listRemoveListNoCase( arguments.lParamFields, arguments.lOutputFields )> --->

<!--- Store Param definition --->
<cfset this.addDefinition( "backup_merge", arguments, this.readBuffer( arguments.sSprocName ) )>

<!--- Generate query tag at the same time --->
<!--- <cfif structKeyExists( arguments, "sBaseCfmDir" ) AND structKeyExists( arguments, "sUdfName" )>
	<!--- <cfset this.generateQueryTag( arguments.sSprocName, arguments.sQueryTagFileName )> --->
	<cfset request.log( "WRITE: #arguments.sBaseCfmDir#/#arguments.sTableName#/dbg_#lCase( arguments.sTableName )#_#lCase( arguments.sUdfName )#.cfm" )>
	<cfset this.writeDefinition( arguments.sSprocName, "#arguments.sBaseCfmDir#/#arguments.sTableName#/dbg_#lCase( arguments.sTableName )#_#lCase( arguments.sUdfName )#.cfm", "CFC" )>
<cfelseif structKeyExists( arguments, "sQueryTagFileName" )>
	<!--- <cfset this.generateQueryTag( arguments.sSprocName, arguments.sQueryTagFileName )> --->
	<cfset request.log( "WRITE: #arguments.sQueryTagFileName#" )>
	<cfset this.writeDefinition( arguments.sSprocName, arguments.sQueryTagFileName, "CFC" )>
</cfif> --->

<cfreturn>

</cffunction>