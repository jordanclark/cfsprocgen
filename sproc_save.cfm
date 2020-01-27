
<cffunction name="saveSproc" output="false">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.saveSuffix#">
<cfargument name="lFilterFields" type="string" default="!PK">
<cfargument name="lInsertFields" type="string" default="!MUTABLE">
<cfargument name="lUpdateFields" type="string" default="!MUTABLE">
<cfargument name="bUseDefaults" type="boolean" default="true">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="bGetRowCount" type="boolean" default="false">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="#this.saveSuffix#">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName )>
<cfset var sTransName = left( replaceNoCase( replace( arguments.sSprocName, "_", "", "all" ), "gsp", "tran_" ), 32 )>
<cfset var bIdentityField = ( listFind( valueList( qMetadata.isIdentity ), 1 ) ? true : false )>

<cfset structAppend( arguments, this.stDefaults, false )>

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lFilterFields = this.filterColumnList( qMetadata, arguments.lFilterFields )>
<cfset arguments.lInsertFields = this.filterColumnList( qMetadata, arguments.lInsertFields )>
<cfset arguments.lUpdateFields = udf.listRemoveListNoCase( this.filterColumnList( qMetadata, arguments.lUpdateFields ), arguments.lFilterFields )>
<cfset arguments.lParamFields = listRemoveDuplicates( listAppend( arguments.lInsertFields, arguments.lFilterFields ), ",", true )>
<cfset arguments.lOutputFields = "">

<cfif bIdentityField>
	<cfset arguments.lOutputFields = "pkIdentity">
	<cfset qMetadata= this.addColumnMetadataRow(
		qMetadata= qMetadata
	,	sTypeName="INT"
	,	sColumnName="pkIdentity"
	,	bPrimaryKeyColumn="0"
	,	isNullable="0"
	,	isComputed="0"
	,	isIdentity="0"
	,	isSearchable="0"
	)>
	<!--- add identity field by refiltering from all --->
	<cfset arguments.lParamFields = this.filterColumnList( qMetadata, listAppend( arguments.lParamFields, "pkIdentity" ) )>
</cfif>
<cfif arguments.bGetRowCount>
	<cfset qMetadata= this.addColumnMetadataRow(
		qMetadata= qMetadata
	,	sTypeName="INT"
	,	sColumnName="rowcount"
	,	bPrimaryKeyColumn="0"
	,	isNullable="0"
	,	isComputed="0"
	,	isIdentity="0"
	,	isSearchable="0"
	)>
	<cfset arguments.lParamFields = listAppend( arguments.lParamFields, "rowcount" )>
	<cfset arguments.lOutputFields = listAppend( arguments.lOutputFields, "rowcount" )>
</cfif>

<cfif NOT listLen( arguments.lFilterFields )>
	<cfset request.log( "!!Error: No fields to filter by. [SaveSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.SaveSproc.NoFilterFields"
		message="No fields to filter by."
	>
<cfelseif NOT listLen( arguments.lUpdateFields )>
	<cfset request.log( "!!Error: No fields to update. [SaveSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.SaveSproc.NoUpdateFields"
		message="No fields to update."
	>
<cfelseif NOT listLen( arguments.lInsertFields )>
	<cfset request.log( "!!Error: No fields to insert. [SaveSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.SaveSproc.NoInsertFields"
		message="No fields to insert."
	>
</cfif>

<!--- New buffer for sproc --->
<cfset this.addBuffer( arguments.sSprocName, "sql", true )>

<!--- Remove an existing sproc --->
<cfset this.appendDropSproc( arguments.sSprocName )>
<cfset this.appendSetOptions()>

<!--- Build the comments --->
<cfset this.appendBlank()>
<cfset this.appendDivide()>
<cfset this.appendCommentLine( "Save a new record into #arguments.sTableName#" )>
<cfset this.appendCommentLine( "based on fields: #replace( arguments.lInsertFields, ',', ', ', 'all' )#" )>
<cfif len( arguments.lUsersPermitted )>
	<cfset this.appendCommentLine( "Accessible to: #replace( arguments.lUsersPermitted, ',', ', ', 'all' )#" )>
</cfif>
<cfset this.appendDivide()>
<cfset this.appendBlank()>

<!--- Here is the meat and bones of it all --->
<cfset this.appendCreateSproc( arguments.sSprocName )>
<cfset this.appendParamFields( qMetadata, arguments.lParamFields, arguments.lOutputFields, arguments.bUseDefaults )>
<cfset this.append( "AS" )>
<cfset this.appendBegin()>
	<cfset this.appendNoCount()>
	
	<cfset this.appendVar( "error", "int", "0", "Add a safe place to hold errors" )>
	<cfset this.appendVar( "spname", "sysname", "Object_Name(@@ProcID)", "Store this sproc's name" )>
	<cfset this.appendVar( "rowcount", "int", "0", "Count the number of rows updated" )>
	<cfset this.appendVar( "exists", "bit", "0", "Used to see if the record already exists" )>
	<cfif bIdentityField>
		<!--- <cfset this.appendVar( "pkIdentity", "int", "NULL", "Store the newly added identity value to this field (after insert)" )> --->
		<cfset this.appendComment( "Store the newly added identity value to this field (after insert)" )>
		<cfset this.append( "SET @pkIdentity = NULL" )>
		<cfset this.appendBlank()>
	</cfif>
	
	<cfif arguments.bErrorCheck>
		<cfset this.appendMakeNullFields( qMetadata, arguments.lFilterFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
		<cfset this.appendCheckFields( qMetadata, arguments.lFilterFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
	</cfif>
	
	<cfset this.append( "BEGIN TRANSACTION;" )>
	<cfset this.appendBlank()>
	<cfset this.indent()>
	
	<!--- Do an Exists check on the record --->
	<cfset this.appendComment( "Finally grab the records we want" )>
	<cfset this.append( "SELECT#this.sTab##this.sTab#@exists = 1" )>
	<cfset this.append( "FROM#this.sTab##this.sTab##this.owner#.#this.getSqlSafeName( arguments.sTableName )#" )>
	<cfset this.appendWhereFields( qMetadata, arguments.lFilterFields )>
	<cfset this.appendBlank()>
			
	<cfset this.append( "IF( @exists = 0 )" )>
		
		<!--- If the record doesn't exist, INSERT --->
		<cfset this.appendBegin()>
			<cfset this.append( "INSERT INTO #this.owner#.#this.getSqlSafeName( arguments.sTableName )# (" )>
			<cfset this.indent()>
				<cfset this.appendSelectFields( qMetadata, arguments.lInsertFields, true )>
			<cfset this.unindent()>
			<cfset this.append( ")" )>
			<cfset this.append( "VALUES ( " )>
			<cfset this.indent()>
				<cfset this.appendValueFields( qMetadata, arguments.lInsertFields, arguments.bUseDefaults, true )>
			<cfset this.unindent()>
			<cfset this.append( ")" )>
			<cfset this.appendBlank()>
			<cfset this.append( "SELECT" )>
			<cfset this.append( this.sTab & "" & this.sTab & "@error = @@ERROR" )>
			<cfset this.append( this.sTab & "," & this.sTab & "@rowcount = @@ROWCOUNT" )>
			<cfif bIdentityField>
				<cfset this.append( this.sTab & "," & this.sTab & "@pkIdentity = SCOPE_IDENTITY()" )>
			</cfif>
		<cfset this.appendEnd()>
	
	<cfset this.append( "ELSE" )>
	
		<!--- Otherwise record exists, UPDATE --->
		<cfset this.appendBegin()>
			<cfset this.append( "UPDATE#this.sTab##this.sTab##this.owner#.#this.getSqlSafeName( arguments.sTableName )#" )>
			<cfset this.append( "SET#this.sTab#" )>
			<cfset this.appendUpdateFields( qMetadata, arguments.lUpdateFields, arguments.bUseDefaults, false )>
			<cfset this.appendWhereFields( qMetadata, arguments.lFilterFields )>
			<cfset this.appendBlank()>
			<cfset this.append( "SELECT" )>
			<cfset this.append( this.sTab & "" & this.sTab & "@error = @@ERROR" )>
			<cfset this.append( this.sTab & "," & this.sTab & "@rowcount = @@ROWCOUNT" )>
			<cfset this.append( this.sTab & ";" )>
		<cfset this.appendEnd()>

		<cfset this.appendBlank()>
		
	<cfset this.unindent()>
	<cfset this.appendBlank()>
	
	<cfset this.appendComment( "Check the transaction for errors and commit or rollback" )>
	<cfset this.appendErrorCheck( true, sTransName )>
	<cfset this.appendBlank()>
	
	<cfset this.appendComment( "Check if any rows were effective, if not return 1 (problem)" )>
	<cfset this.append( "IF( @rowcount = 0 )" )>
	<cfset this.appendBegin()>
		<cfset this.append( "RETURN 1;" )>
	<cfset this.appendEnd()>
	<cfset this.appendBlank()>
	
	<cfset this.append( "RETURN 0;" )>

<cfset this.appendEnd()>
<cfset this.append( "GO" )>
<cfset this.appendBlank()>
<cfset this.appendGrantObject( arguments.sSprocName, arguments.lUsersPermitted )>

<cfset arguments.qFields = qMetadata>
<cfset arguments.lInputFields = udf.listRemoveListNoCase( arguments.lParamFields, arguments.lOutputFields )>

<!--- Store Param definition --->
<cfset this.addDefinition( "save", arguments, this.readBuffer( arguments.sSprocName ) )>

<!--- Generate query tag at the same time --->
<cfif structKeyExists( arguments, "sTagDir" ) AND structKeyExists( arguments, "sUdfName" )>
	<!--- <cfset this.generateQueryTag( arguments.sSprocName, arguments.sQueryTagFileName )> --->
	<cfset request.log( "WRITE: #arguments.sTagDir#/#arguments.sTableName#/dbg_#lCase( arguments.sTableName )#_#lCase( arguments.sUdfName )#.cfm" )>
	<cfset this.writeDefinition( arguments.sSprocName, "#arguments.sTagDir#/#arguments.sTableName#/dbg_#lCase( arguments.sTableName )#_#lCase( arguments.sUdfName )#.cfm", "CFC" )>
<cfelseif structKeyExists( arguments, "sQueryTagFileName" )>
	<!--- <cfset this.generateQueryTag( arguments.sSprocName, arguments.sQueryTagFileName )> --->
	<cfset request.log( "WRITE: #arguments.sQueryTagFileName#" )>
	<cfset this.writeDefinition( arguments.sSprocName, arguments.sQueryTagFileName, "CFC" )>
</cfif>

<cfreturn>

</cffunction>