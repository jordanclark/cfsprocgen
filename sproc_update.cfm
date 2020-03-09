
<cffunction name="updateSproc" output="false">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.updateSuffix#">
<cfargument name="lFilterFields" type="string" default="!PK">
<cfargument name="lUpdateFields" type="string" default="*">
<cfargument name="bUseDefaults" type="boolean" default="true">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="bGetRowCount" type="boolean" default="false">
<cfargument name="lUsersPermitted" type="string" default="">
<cfargument name="sUdfName" type="string" default="#this.updateSuffix#">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName )>

<cfset structAppend( arguments, this.stDefaults, false )>

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lFilterFields = this.filterColumnList( qMetadata, arguments.lFilterFields )>
<cfset arguments.lUpdateFields = this.filterColumnList( qMetadata, arguments.lUpdateFields )>
<cfset arguments.lUpdateFields = this.filterColumnList( qMetadata, udf.listRemoveListNoCase( arguments.lUpdateFields, arguments.lFilterFields ) )>
<cfset arguments.lParamFields = this.filterColumnList( qMetadata, listAppend( arguments.lUpdateFields, arguments.lFilterFields ) )>
<cfset arguments.lOutputFields = "">

<cfif arguments.bGetRowCount>
	<cfset qMetadata= this.addColumnMetadataRow(
		qMetadata= qMetadata
	,	sTypeName="int"
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

<cfif NOT listLen( arguments.lUpdateFields )>
	<cfset request.log( "!!Error: No fields to update. [UpdateSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.UpdateSproc.NoUpdateFields"
		message="No fields to update."
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
<cfif listLen( arguments.lFilterFields )>
	<cfset this.appendCommentLine( "Update a single record from #arguments.sTableName#" )>
	<cfset this.appendCommentLine( "based on fields: #replace( arguments.lFilterFields, ',', ', ', 'all' )#" )>
<cfelse>
	<cfset this.appendCommentLine( "Update ALL records from #arguments.sTableName#" )>
</cfif>
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
	
	<cfif arguments.bErrorCheck>
		<cfset this.appendMakeNullFields( qMetadata, arguments.lFilterFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
		<cfset this.appendCheckFields( qMetadata, arguments.lFilterFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
	</cfif>
	
	<cfset this.append( "UPDATE#this.sTab##this.sTab##this.owner#.#this.getSqlSafeName( arguments.sTableName )#" )>
	<cfset this.append( "SET#this.sTab#" )>
	<cfset this.appendUpdateFields( qMetadata, arguments.lUpdateFields, arguments.bUseDefaults, false, false )>
	<cfset this.appendWhereFields( qMetadata, arguments.lFilterFields )>
	<cfset this.appendBlank()>
	<cfset this.append( "SELECT" )>
	<cfset this.append( this.sTab & "" & this.sTab & "@error = @@ERROR" )>
	<cfset this.append( this.sTab & "," & this.sTab & "@rowcount = @@ROWCOUNT" )>
	<cfset this.append( this.sTab & ";" )>
	
	<cfset this.appendBlank()>
	<cfset this.appendErrorCheck()>
	
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
<cfset this.addDefinition( "update", arguments, this.readBuffer( arguments.sSprocName ) )>

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
