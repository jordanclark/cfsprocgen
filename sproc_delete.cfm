
<cffunction name="deleteSproc" output="false">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.deleteSuffix#">
<cfargument name="lFilterFields" type="string" default="!PK">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="bSearchFields" type="boolean" default="false">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="#this.deleteSuffix#">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName )>

<cfset structAppend( arguments, this.stDefaults, false )>

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lFilterFields = this.filterColumnList( qMetadata, arguments.lFilterFields )>	
<cfset arguments.lParamFields = arguments.lFilterFields>
<cfset arguments.lOutputFields = "">

<cfif NOT listLen( arguments.lFilterFields )>
	<cfset request.log( "!!Error: No fields to filter by. [DeleteSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.DeleteSproc.NoFilterFields"
		message="No fields to filter by."
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
	<cfset this.appendCommentLine( "Delete a single record from #arguments.sTableName#" )>
	<cfset this.appendCommentLine( "based on fields: #replace( arguments.lFilterFields, ',', ', ', 'all' )#" )>
<cfelse>
	<cfset this.appendCommentLine( "Delete ALL records from #arguments.sTableName#" )>
</cfif>
<cfif len( arguments.lUsersPermitted )>
	<cfset this.appendCommentLine( "Accessible to: #replace( arguments.lUsersPermitted, ',', ', ', 'all' )#" )>
</cfif>
<cfset this.appendDivide()>
<cfset this.appendBlank()>

<!--- Here is the meat and bones of it all --->
<cfset this.appendCreateSproc( arguments.sSprocName )>
<cfset this.appendParamFields( qMetadata, arguments.lFilterFields, arguments.lOutputFields, false, arguments.bSearchFields )>
<cfset this.append( "AS" )>
<cfset this.appendBegin()>
	<cfset this.appendNoCount()>
	
	<cfset this.appendVar( "error", "int", "0", "Add a safe place to hold errors" )>
	<!--- <cfset this.appendVar( "spname", "sysname", "Object_Name(@@ProcID)", "Store this sproc's name" )> --->
	<cfset this.appendVar( "rowcount", "int", "0", "Count the number of rows updated" )>
	
	<cfif arguments.bErrorCheck>
		<cfset this.appendMakeNullFields( qMetadata, arguments.lFilterFields )>
		<cfset this.appendBlank()>
		<cfif NOT arguments.bSearchFields>
			<cfset this.appendCheckFields( qMetadata, arguments.lFilterFields )>
			<cfset this.appendBlank()>
		</cfif>
	</cfif>
	
	<cfset this.append( "DELETE#this.sTab##this.sTab##this.owner#.#this.getSqlSafeName( arguments.sTableName )#" )>
	<cfset this.appendWhereFields( qMetadata, arguments.lFilterFields, arguments.bSearchFields )>
	
	<cfset this.appendBlank()>
	<cfset this.append( "SELECT" )>
	<cfset this.append( this.sTab & "" & this.sTab & "@error = @@ERROR" )>
	<cfset this.append( this.sTab & "," & this.sTab & "@rowcount = @@ROWCOUNT" )>
	<cfset this.append( this.sTab & ";" )>
	
	<cfset this.appendBlank()>
	<!--- <cfset this.appendErrorCheck()> --->
	
	<!---
	<cfset this.appendBlank()>
	<cfset this.appendComment( "Check if any rows were effective, if not return 1 (problem)" )>
	<cfset this.append( "IF( @rowcount = 0 )" )>
	<cfset this.appendBegin()>
		<cfset this.append( "RETURN 1;" )>
	<cfset this.appendEnd()>
	<cfset this.appendBlank()>
	--->
	
	<cfset this.append( "RETURN @error;" )>
	
	<cfset this.appendEnd()>
<cfset this.append( "GO" )>
<cfset this.appendBlank()>
<cfset this.appendGrantObject( arguments.sSprocName, arguments.lUsersPermitted )>

<cfset arguments.qFields = qMetadata>
<cfset arguments.lInputFields = udf.listRemoveListNoCase( arguments.lParamFields, arguments.lOutputFields )>

<!--- Store Param definition --->
<cfset this.addDefinition( "delete", arguments, this.readBuffer( arguments.sSprocName ) )>

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
