
<cffunction name="generateQueryTag" output="true" returnType="string">

<cfargument name="stDef" type="struct" required="true">

<cfset var sItem = "">
<cfset var nSetSelect = "">
<cfset var sCFMLCode = "">
<cfset var sLComment = "<!" & "---">
<cfset var sRComment = "---" & ">" />

<!--- overwrite any of the arguments with whatever is passed --->
<cfset structAppend( stDef.stArgs, arguments, true )>

<!--- name file after sproc if not otherwise provided --->
<!--- <cfif NOT structKeyExists( stDef.stArgs.sFileName )>
	<cfset arguments.sFileName = replace( stDef.stArgs.sSprocName, "gsp_", "qry_", "one" )>
</cfif> --->

<!--- New buffer for sproc --->
<cfset this.addBuffer( "cfm_#this.owner#.#stDef.stArgs.sSprocName#", "cfm", true )>

<!--- only execute query tag once --->
<cfset this.append( '<cfif isDefined( "thisTag.executionMode" ) AND thisTag.executionMode IS "end">' )>
<cfset this.indent()>
	<cfset this.append( '<cfexit method="exitTemplate">' )>
<cfset this.unindent()>
<cfset this.append( '</cfif>' )>
<cfset this.appendBlank()>

<!--- parameters for the different query types --->
<cfswitch expression="#stDef.sType#">
	<cfcase value="select">
		<cfset this.append( '<cfparam name="attributes.query" type="string">' )>
		<cfset this.append( '<cfparam name="attributes.maxRows" type="numeric" default="-1">' )>
		<cfset this.append( '<cfparam name="attributes.r_recordCount" type="string" default="">' )>
	</cfcase>
	<cfcase value="selectSet">
		<cfset this.append( '<cfparam name="attributes.query" type="string">' )>
		<cfset this.append( '<cfparam name="attributes.selectSet" type="string">' )>
		<cfset this.append( '<cfparam name="attributes.maxRows" type="numeric" default="-1">' )>
		<cfset this.append( '<cfparam name="attributes.r_recordCount" type="string" default="">' )>
	</cfcase>
	<cfcase value="count">
		<cfset this.append( '<cfparam name="attributes.r_count" type="string">' )>
	</cfcase>
	<cfcase value="exists">
		<cfset this.append( '<cfparam name="attributes.r_exists" type="string">' )>
	</cfcase>
</cfswitch>
<cfset this.append( '<cfparam name="attributes.r_statusCode" type="string" default="">' )>

<!--- add parameters for the input fields --->
<cfloop index="sItem" list="#stDef.stArgs.lInputFields#">
	<cfset this.append( '<cfparam name="attributes.#sItem#" type="#stDef.stFields[ sItem ].cftype#"' )>
	<cfif len( stDef.stFields[ sItem ].default ) OR stDef.stFields[ sItem ].nullable>
		<cfset this.append( ' default="#stDef.stFields[ sItem ].default#"', false )>
	</cfif>
	<cfset this.append( '>', false )>
</cfloop>
<cfset this.appendBlank()>

<!--- comment to remind what fields are included in select sets --->
<cfif structKeyExists( stDef.stArgs, "sSetSelect" )>
	<cfset this.append( sLComment )>
	<cfloop index="nSetSelect" from="1" to="#stDef.stArgs.nSetSelectLength#">
		<cfset this.append( 'Select Set ###nSetSelect# = #listGetAt( stDef.stArgs.lSetSelectFields, nSetSelect, "|" )#' )>
	</cfloop>
	<cfset this.append( sRComment )>
	<cfset this.appendBlank()>
</cfif>

<!--- build the sproc tag --->
<cfset this.append( '<cfstoredproc' )>
<cfif structKeyExists( stDef.stArgs, "sSetSelect" )>
	<cfset this.append( ' procedure="#this.owner#.#stDef.stArgs.sSprocName###arguments.selectSet##"', false )>
<cfelse>
	<cfset this.append( ' procedure="#this.owner#.#stDef.stArgs.sSprocName#"', false )>
</cfif>
<cfset this.append( ' dataSource="#stDef.stArgs.sDSN#" returnCode="true">', false )>
<cfset this.indent()>

	<!--- Loop over the individual sproc params --->
	<cfloop index="sItem" list="#stDef.stArgs.lParamFields#">
		<cfset this.append( '<cfprocparam type="#stDef.stFields[ sItem ].type#"' )>
		<cfif len( stDef.stFields[ sItem ].maxLength )>
			<cfset this.append( ' maxLength="#stDef.stFields[ sItem ].maxLength#"', false )>
		</cfif>
		<cfif len( stDef.stFields[ sItem ].scale ) AND listFindNoCase( "decimal,double,float,money,smallmoney", stDef.stFields[ sItem ].sqlType )>
			<cfset this.append( ' scale="#stDef.stFields[ sItem ].scale#"', false )>
		</cfif>
		<cfset this.append( ' dbVarName="#stDef.stFields[ sItem ].varName#"', false )>
		<cfif findNoCase( "OUT", stDef.stFields[ sItem ].type )>
			<cfset this.append( ' variable="attributes.#sItem#"', false )>
		</cfif>
		<cfif findNoCase( "IN", stDef.stFields[ sItem ].type )>
			<cfset this.append( ' value="##attributes.#sItem###"', false )>
		</cfif>
		<cfset this.appendOn( ' cfSqlType="#stDef.stFields[ sItem ].cfSqlType#"' )>
		<cfif stDef.stFields[ sItem ].nullable OR len( stDef.stFields[ sItem ].default )>
			<cfset this.append( ' null="##( NOT len( attributes.#sItem# ) ? true : false )##"', false )>
		<cfelse>
			<cfset this.append( ' null="false"', false )>
		</cfif>
		<cfset this.append( '>', false )>
	</cfloop>

	<!--- return the query results --->
	<cfif listFindNoCase( "select,selectSet", stDef.sType )>
		<cfset this.append( '<cfprocresult name="#stDef.stArgs.sQueryName#" resultSet="1" maxRows="##attributes.maxrows##">' )>
	</cfif>

<cfset this.unindent()>
<cfset this.append( '</cfstoredproc>' )>
<cfset this.appendBlank()>

<!--- return relavant data --->
<cfif stDef.sType IS "select" OR stDef.sType IS "selectSet">
	<cfset this.append( '<cfset "##attributes.query##" = #stDef.stArgs.sQueryName#>' )>
	<cfset this.append( '<cfset "##attributes.r_recordCount##" = #stDef.stArgs.sQueryName#.recordCount>' )>
<cfelseif stDef.sType IS "count">
	<cfset this.append( '<cfset "##attributes.r_count##" = attributes.count>' )>
<cfelseif stDef.sType IS "exists">
	<cfset this.append( '<cfset "##attributes.r_exists## = attributes.exists>' )>
<cfelse><!--- save,insert,update --->
	<cfset this.append( sLComment & ' no output ' & sRComment )>
</cfif>

<!--- return the status code --->
<cfif structKeyExists( stDef.stArgs, "sSetSelect" )>
	<cfset this.append( '<cfset "##attributes.r_statusCode##" = evaluate( "#stDef.stArgs.sSprocName###arguments.selectSet##.statusCode" )>' )>
<cfelse>
	<cfset this.append( '<cfset "##attributes.r_statusCode##" = #stDef.stArgs.sSprocName#.statusCode>' )>
</cfif>
<cfset this.appendBlank()>

<!--- append original sproc t-sql to cfml code for easy reference --->
<cfset this.appendLine( sLComment & ' Actual Stored Procedure T-SQL Code ' & this.sNewLine )>
<cfset this.appendLine( ' --><cfquery>' )>
<cfset this.append( stDef.sSql )>
<cfset this.appendBlank()>
<cfset this.append( sRComment )>

<cfreturn this.readBuffer( "cfm_#this.owner#.#stDef.stArgs.sSprocName#", "*" )>

</cffunction>