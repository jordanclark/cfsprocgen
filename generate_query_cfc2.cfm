
<!--- stArgs can contain: output, returnType, access, roles, display --->
<cffunction name="generateQueryCFC" output="true" returnType="string">

<cfargument name="stDef" type="struct" required="true">
<cfset var local = {}>

<cfset local.sItem = "">
<cfset local.nSetSelect = "">
<cfset local.sLComment = "<!" & "---">
<cfset local.sRComment = "---" & ">">
<cfset local.sName = "">

<!--- overwrite any of the arguments with whatever is passed --->
<cfset structAppend( stDef.stArgs, arguments, true )>
<!--- <cfset request.log( stDef )> --->

<cfif structKeyExists( stDef.stArgs, "sUdfName" )>
	<cfset local.sName = "db_" & stDef.stArgs.sUdfName>
<cfelse>
	<cfset local.sName = "db_" & replaceList( stDef.stArgs.sSprocName, "gsp_", "" )>
</cfif>
<cfset local.sName = this.camelCase( local.sName )>

<!--- New buffer for sproc --->
<cfset this.addBuffer( "cfc_#this.owner#.#stDef.stArgs.sSprocName#", "cfm", true )>

<cfset this.append( '<cffunction name="#local.sName#" output="false"' )>
<cfloop index="local.udfArg" list="access,roles,display">
	<cfif structKeyExists( stDef.stArgs, "sUdf" & local.udfArg )>
		<cfset this.appendOn( ' #local.udfArg#="#stDef.stArgs[ 'sUdf' & local.udfArg ]#"' )>
	</cfif>
</cfloop>
<cfif listFindNoCase( "select,selectSet", stDef.sType )>
	 <cfset this.appendOn( ' returnType="query">' )>
<cfelseif listFindNoCase( "exists", stDef.sType )>
	 <cfset this.appendOn( ' returnType="boolean">' )>
<cfelseif listFindNoCase( "count", stDef.sType )>
	 <cfset this.appendOn( ' returnType="numeric">' )>
<cfelse>
	<cfset this.appendOn( '>' )>
</cfif>
<cfset this.indent()>
<cfset this.appendBlank()>

<!--- add parameters for the input fields --->
<cfloop index="local.sItem" list="#stDef.stArgs.lInputFields#">
	<cfset this.appendLine( '<cfargument name="#local.sItem#"' )>
	<!--- hack in for <cfargument> which wont allow a null "" numeric value to be passed in --->
	<cfif NOT len( stDef.stFields[ local.sItem ].default ) AND stDef.stFields[ local.sItem ].nullable>
		<cfset this.appendOn( ' type="string"' )>
	<cfelse>
		<cfset this.appendOn( ' type="#stDef.stFields[ local.sItem ].cfType#"' )>
	</cfif>
	<!--- give a default value if possible --->
	<cfif structKeyExists( stDef.stArgs, "bSearchFields" ) AND stDef.stArgs.bSearchFields AND stDef.stFields[ local.sItem ].searchable>
		<!--- <cfset this.appendOn( ' default=""' )> --->
	<cfelseif len( stDef.stFields[ local.sItem ].default ) OR stDef.stFields[ local.sItem ].nullable>
		<cfset this.appendOn( ' default="#stDef.stFields[ local.sItem ].default#"' )>
	<cfelse>
		<cfset this.appendOn( ' required="true"' )>
	</cfif>
	<cfset this.appendOn( ' hint="' )>
	<cfif stDef.stFields[ local.sItem ].cfType IS NOT "string" AND NOT len( stDef.stFields[ local.sItem ].default ) AND stDef.stFields[ local.sItem ].nullable>
		<cfset this.appendOn( 'Type is #uCase( stDef.stFields[ local.sItem ].cfType )#, but is nullable. ' )>
	</cfif>
	<cfset this.appendOn( '"' )>
	<cfset this.appendOn( '>' )>
</cfloop>
<!--- parameters for the different query types --->
<cfif listFindNoCase( "select,selectSet", stDef.sType )>
	<cfset this.appendLine( '<cfargument name="maxRows" type="numeric" default="-1">' )>
</cfif>
<!--- <cfif structKeyExists( stDef.stArgs, "bDebuggable" ) AND stDef.stArgs.bDebuggable>
	<cfset this.appendLine( '<cfargument name="debug" type="boolean" default="false">' )>
</cfif> --->

<!--- comment to remind what fields are included in select sets --->
<cfif structKeyExists( stDef.stArgs, "sSetSelect" )>
	<cfset this.appendBlank()>
	<cfset this.appendLine( local.sLComment )>
	<cfloop index="local.nSetSelect" from="1" to="#stDef.stArgs.nSetSelectLength#">
		<cfset this.appendLine( 'Select Set ###local.nSetSelect# = #listGetAt( stDef.stArgs.lSetSelectFields, local.nSetSelect, "|" )#' )>
	</cfloop>
	<cfset this.appendLine( local.sRComment )>
</cfif>

<cfset this.appendBlank()>
<cfset this.appendLine( '<cfset var sproc = 0>' )>
<cfif listFindNoCase( "select,selectSet", stDef.sType )>
	<cfset this.appendLine( '<cfset var #stDef.stArgs.sQueryName# = 0>' )>
</cfif>
<cfif stDef.sType IS "count">
	<cfset this.appendLine( '<cfset arguments.count = 0>' )>
<cfelseif stDef.sType IS "exists">
	<cfset this.appendLine( '<cfset arguments.exists = false>' )>
</cfif>

<!--- build the sproc tag --->
<cfset this.appendBlank()>
<cfset this.appendLine( '<cfstoredproc' )>
<cfif structKeyExists( stDef.stArgs, "sSetSelect" )>
	<cfset this.appendOn( ' procedure="#this.owner#.#stDef.stArgs.sSprocName###arguments.selectSet##"' )>
<cfelse>
	<cfset this.appendOn( ' procedure="#this.owner#.#stDef.stArgs.sSprocName#"' )>
</cfif>
<cfset this.appendOn( ' result="sproc"' )>
<cfif structKeyExists( stDef.stArgs, "bDebuggable" ) AND stDef.stArgs.bDebuggable>
	<cfset this.appendOn( ' debug="##this.debug##"' )>
</cfif>
<cfif structKeyExists( stDef.stArgs, "bStatusCode" ) AND stDef.stArgs.bStatusCode>
	<cfset this.appendOn( ' returnCode="true"' )>
<cfelse>
	<cfset this.appendOn( ' returnCode="false"' )>
</cfif>
<cfset this.appendOn( ' dataSource="#stDef.stArgs.sDSN#">' )>
<cfset this.indent()>

	<!--- Loop over the individual sproc params --->
	<cfloop index="local.sItem" list="#stDef.stArgs.lParamFields#">
	<cfif structKeyExists( stDef.stArgs, "bSearchFields" ) AND stDef.stArgs.bSearchFields AND stDef.stFields[ local.sItem ].searchable>
		<cfset this.appendLine( '<cfif structKeyExists( arguments, "#local.sItem#" )>' )>
		<cfset this.indent()>
	</cfif>
		<cfset this.appendLine( '<cfprocparam type="#stDef.stFields[ local.sItem ].type#"' )>
		<cfset this.appendOn( ' dbVarName="#stDef.stFields[ local.sItem ].varName#"' )>
		<cfif findNoCase( "OUT", stDef.stFields[ local.sItem ].type )>
			<cfset this.appendOn( ' variable="arguments.#local.sItem#"' )>
		</cfif>
		<cfif findNoCase( "IN", stDef.stFields[ local.sItem ].type )>
			<cfset this.appendOn( ' value="##arguments.#local.sItem###"' )>
		</cfif>
		<cfset this.appendOn( ' cfSqlType="#stDef.stFields[ local.sItem ].cfSqlType#"' )>
		<cfif len( stDef.stFields[ local.sItem ].maxLength ) AND stDef.stFields[ local.sItem ].maxLength GT -1>
			<cfset this.appendOn( ' maxLength="#stDef.stFields[ local.sItem ].maxLength#"' )>
		</cfif>
		<cfif len( stDef.stFields[ local.sItem ].scale ) AND listFindNoCase( "decimal,double,float,money,smallmoney", stDef.stFields[ local.sItem ].sqlType )>
			<cfset this.appendOn( ' scale="#stDef.stFields[ local.sItem ].scale#"' )>
		</cfif>
		<cfif stDef.stFields[ local.sItem ].type IS NOT "OUT" AND ( stDef.stFields[ local.sItem ].nullable OR len( stDef.stFields[ local.sItem ].default ) OR ( structKeyExists( stDef.stArgs, "bSearchFields" ) AND stDef.stArgs.bSearchFields ) )>
			<cfset this.appendOn( ' null="##( NOT len( arguments.#local.sItem# ) )##"' )>
		<cfelse>
			<cfset this.appendOn( ' null="false"' )>
		</cfif>
		<cfset this.appendOn( '>' )>
	<cfif structKeyExists( stDef.stArgs, "bSearchFields" ) AND stDef.stArgs.bSearchFields AND stDef.stFields[ local.sItem ].searchable>
		<cfset this.unindent()>
		<cfset this.appendLine( '</cfif>' )>
	</cfif>
	</cfloop>

	<!--- return the query results --->
	<cfif listFindNoCase( "select,selectSet", stDef.sType )>
		<cfset this.appendLine( '<cfprocresult name="#stDef.stArgs.sQueryName#" resultSet="1" maxRows="##arguments.maxrows##">' )>
	</cfif>

<cfset this.unindent()>
<cfset this.appendLine( '</cfstoredproc>' )>

<!--- return the status code --->
<cfif structKeyExists( stDef.stArgs, "bStatusCode" ) AND stDef.stArgs.bStatusCode>
	<cfset this.appendBlank()>
	<cfset this.appendLine( '<cfset request.log( "#this.owner#.#stDef.stArgs.sSprocName# StatusCode[##sproc.statusCode##] ExecutionTime[##sproc.executionTime##]" )>' )>
</cfif>
<cfset this.appendBlank()>

<!--- return relavant data --->
<cfif stDef.sType IS "select" OR stDef.sType IS "selectSet">
	<cfset this.appendLine( '<cfreturn #stDef.stArgs.sQueryName#>' )>
<cfelseif stDef.sType IS "count">
	<cfset this.appendLine( '<cfreturn arguments.count>' )>
<cfelseif stDef.sType IS "exists">
	<cfset this.appendLine( '<cfreturn arguments.exists>' )>
<cfelse><!--- save,insert,update --->
	<cfset this.appendLine( local.sLComment & ' no output ' & local.sRComment )>
	<!--- could uncomment next line to return the statusCode, but I found it kind of useless --->
	<cfif structKeyExists( stDef.stArgs, "bStatusCode" ) AND stDef.stArgs.bStatusCode>
		<cfset this.appendLine( '<cfreturn sproc.statusCode IS 0>' )>
	<cfelse>
		<cfset this.appendLine( '<cfreturn>' )>
	</cfif>
</cfif>

<cfset this.appendBlank()>
<cfset this.unindent()>
<cfset this.appendLine( '</cffunction>' )>

<!--- add real function name to cfc --->
<cfset this.appendBlank()>
<cfset this.appendLine( '<cfset this.#right( local.sName, len( local.sName ) - 2  )# = variables.#local.sName#>' )>
<cfset this.appendLine( '<cfset structDelete( variables, "#local.sName#" )>' )>

<cfset this.appendBlank()>

<cfif structKeyExists( stDef.stArgs, "bCfcIncludeSql" ) AND stDef.stArgs.bCfcIncludeSql>
	<!--- append original sproc t-sql to cfml code for easy reference --->
	<cfset this.appendLine( local.sLComment & ' Actual Stored Procedure T-SQL Code -->' & this.sNewLine )>
	<cfset this.appendLine( stDef.sSql )>
	<cfset this.appendBlank()>
	<cfset this.appendLine( local.sRComment )>
</cfif>

<cfreturn this.readBuffer( "cfc_#this.owner#.#stDef.stArgs.sSprocName#", "*" )>

</cffunction>