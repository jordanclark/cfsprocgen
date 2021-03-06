
<cffunction name="insertSproc" output="false">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.insertSuffix#">
<cfargument name="lInsertFields" type="string" default="!MUTABLE">
<cfargument name="bUseDefaults" type="boolean" default="true">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="#this.insertSuffix#">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName, "*" )>
<cfset var sTransName = left( replaceNoCase( replace( arguments.sSprocName, "_", "", "all" ), "gsp", "tran_" ), 32 )>
<cfset var bIdentityField = ( listFind( valueList( qMetadata.isIdentity ), 1 ) ? true : false )>

<cfset structAppend( arguments, this.stDefaults, false )>

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lInsertFields = this.filterColumnList( qMetadata, arguments.lInsertFields )>
<cfset arguments.lParamFields = arguments.lInsertFields>
<cfset arguments.lOutputFields = "">


<cfif NOT listLen( arguments.lInsertFields )>
	<cfset request.log( qMetadata )>
	<cfset request.log( sTransName )>
	<cfset request.log( arguments )>
	<cfset request.log( "!!Error: No fields to insert. [InsertSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.InsertSproc.NoInsertFields"
		message="No fields to insert."
	>
</cfif>

<!--- if table has identity field, add to field listing --->
<cfif bIdentityField>
	<cfset arguments.lOutputFields = "pkIdentity">
	<cfset qMetadata= this.addColumnMetadataRow(
		qMetadata= qMetadata
	,	sTypeName="int"
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

<!--- New buffer for sproc --->
<cfset this.addBuffer( arguments.sSprocName, "sql", true )>

<!--- Remove an existing sproc --->
<cfset this.appendDropSproc( arguments.sSprocName )>
<cfset this.appendSetOptions()>

<!--- Build the comments --->
<cfset this.appendBlank()>
<cfset this.appendDivide()>
<cfset this.appendCommentLine( "Insert a new record into #arguments.sTableName#" )>
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
	<cfif bIdentityField>
		<!--- <cfset this.appendVar( "pkIdentity", "int", "NULL", "Store the newly added identity value to this field (after insert)" )> --->
		<cfset this.appendComment( "Store the newly added identity value to this field (after insert)" )>
		<cfset this.append( "SET @pkIdentity = NULL" )>
		<cfset this.appendBlank()>
	</cfif>
	
	<cfif arguments.bErrorCheck>
		<cfset this.appendMakeNullFields( qMetadata, arguments.lInsertFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
		<cfset this.appendCheckFields( qMetadata, arguments.lInsertFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
	</cfif>
	
	<cfif bIdentityField>
		<cfset this.append( "BEGIN TRANSACTION;" )>
		<cfset this.appendBlank()>
		<cfset this.indent()>
	</cfif>

	<cfset this.append( "INSERT INTO #this.owner#.#this.getSqlSafeName( arguments.sTableName )# (" )>
	<cfset this.indent()>
		<cfset this.appendSelectFields( qMetadata, arguments.lInsertFields, true, false )>
	<cfset this.unindent()>
	<cfset this.append( ")" )>
	<cfset this.appendLine( "VALUES ( " )>
	<cfset this.indent()>
		<cfset this.appendValueFields( qMetadata, arguments.lInsertFields, arguments.bUseDefaults, true, false )>
	<cfset this.unindent()>
	<cfset this.append( ")" )>
	<cfset this.appendBlank()>
	<cfset this.append( "SELECT" )>
	<cfset this.append( this.sTab & "" & this.sTab & "@error = @@ERROR" )>
	<cfset this.append( this.sTab & "," & this.sTab & "@rowcount = @@ROWCOUNT" )>
	<cfif bIdentityField>
		<cfset this.append( this.sTab & "," & this.sTab & "@pkIdentity = SCOPE_IDENTITY()" )>
	</cfif>
	<cfset this.append( this.sTab & ";" )>
	
	<cfset this.appendBlank()>
	<cfif bIdentityField>
		<cfset this.unindent()>
		<cfset this.appendComment( "Check the transaction for errors and commit or rollback" )>
	</cfif>
	
	<!--- only manage transaction if inserting into identity table --->
	<cfif bIdentityField>
		<cfset this.appendErrorCheck( true, sTransName )>
		<cfset this.appendBlank()>
	</cfif>
	
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
<cfset this.addDefinition( "insert", arguments, this.readBuffer( arguments.sSprocName ) )>

<!--- Generate query tag at the same time --->
<cfif structKeyExists( arguments, "sBaseCfmDir" ) AND structKeyExists( arguments, "sUdfName" )>
	<!--- <cfset this.generateQueryTag( arguments.sSprocName, arguments.sQueryTagFileName )> --->
	<cfset request.log( "WRITE: #arguments.sBaseCfmDir#/#arguments.sTableName#/dbg_#lCase( arguments.sTableName )#_#lCase( arguments.sUdfName )#.cfm" )>
	<cfset this.writeDefinition( arguments.sSprocName, "#arguments.sBaseCfmDir#/#arguments.sTableName#/dbg_#lCase( arguments.sTableName )#_#lCase( arguments.sUdfName )#.cfm", "CFC" )>
<cfelseif structKeyExists( arguments, "sQueryTagFileName" )>
	<!--- <cfset this.generateQueryTag( arguments.sSprocName, arguments.sQueryTagFileName )> --->
	<cfset request.log( "WRITE: #arguments.sQueryTagFileName#" )>
	<cfset this.writeDefinition( arguments.sSprocName, arguments.sQueryTagFileName, "CFC" )>
</cfif>

<cfreturn>

</cffunction>