
<cffunction name="selectSproc" output="false">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.selectSuffix#">
<cfargument name="lFilterFields" type="string" default="!NOTNULL,!COMPARABLE">
<cfargument name="lSelectFields" type="string" default="*">
<cfargument name="sOrderBy" type="string" default="">
<cfargument name="nTopRows" type="numeric" default="-1">
<cfargument name="bErrorCheck" type="boolean" default="false">
<cfargument name="bSearchFields" type="boolean" default="true">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="#this.selectSuffix#">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName )>

<cfset structAppend( arguments, this.stDefaults, false )>

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lFilterFields = this.filterColumnList( qMetadata, arguments.lFilterFields )>
<cfset arguments.lSelectFields = this.filterColumnList( qMetadata, arguments.lSelectFields )>
<cfset arguments.lParamFields = arguments.lFilterFields>
<cfset arguments.lOutputFields = "">

<cfif NOT listLen( arguments.lSelectFields )>
	<cfset request.log( "!!Error: No fields to filter by. [SelectSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.SelectSproc.NoSelectFields"
		message="No fields to select."
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
	<cfset this.appendCommentLine( "Select a single record from #arguments.sTableName#" )>
	<cfset this.appendCommentLine( "based on fields: #replace( arguments.lFilterFields, ',', ', ', 'all' )#" )>
<cfelse>
	<cfset this.appendCommentLine( "Select ALL records from #arguments.sTableName#" )>
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
	
	<!--- <cfset this.appendVar( "error", "int", "0", "Add a safe place to hold errors" )> --->
	<!--- <cfset this.appendVar( "spname", "sysname", "Object_Name(@@ProcID)", "Store this sproc's name" )> --->
	
	<!--- <cfif arguments.bErrorCheck>
		<cfset this.appendMakeNullFields( qMetadata, arguments.lFilterFields )>
		<cfset this.appendBlank()>
		<cfif NOT arguments.bSearchFields>
			<cfset this.appendCheckFields( qMetadata, arguments.lFilterFields )>
			<cfset this.appendBlank()>
		</cfif>
	</cfif> --->
	
	<cfset this.appendComment( "Finally grab the records we want" )>
	
	<cfset this.append( "SELECT#this.sTab#" )>
	<cfif arguments.nTopRows GT -1>
		<cfset this.append( "TOP (#arguments.nTopRows#)", false )>
	</cfif>
	<cfset this.indent()>
		<cfset this.appendSelectFields( qMetadata, arguments.lSelectFields, false, false )>
	<cfset this.unindent()>
	<cfset this.append( "FROM#this.sTab##this.sTab##this.owner#.#this.getSqlSafeName( arguments.sTableName )#" )>
	<cfset this.appendWhereFields( qMetadata, arguments.lFilterFields, arguments.bSearchFields )>
	<cfif len( arguments.sOrderBy )>
		<cfset this.append( "ORDER BY#this.sTab##arguments.sOrderBy#" )>
	</cfif>
	
	<!--- 
	<cfset this.appendBlank()>
	<cfset this.append( "SELECT @error = @@ERROR;" )>
	<cfset this.appendErrorCheck()>
	
	<cfset this.append( "RETURN @error;" )>
	--->
	
	<cfset this.append( "RETURN @@ERROR;" )>
	
<cfset this.appendEnd()>
<cfset this.append( "GO" )>
<cfset this.appendBlank()>
<cfset this.appendGrantObject( arguments.sSprocName, arguments.lUsersPermitted )>

<cfset arguments.qFields = qMetadata>
<cfset arguments.lInputFields = udf.listRemoveListNoCase( arguments.lParamFields, arguments.lOutputFields )>

<!--- Store Param definition --->
<cfset this.addDefinition( "select", arguments, this.readBuffer( arguments.sSprocName ) )>

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