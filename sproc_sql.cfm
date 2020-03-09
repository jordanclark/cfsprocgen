
<cffunction name="sql" output="false">

<cfargument name="sSprocName" type="string" required="true">
<cfargument name="sSql" type="string" required="true">
<cfargument name="lFilterFields" type="string" default="">
<cfargument name="lParamFields" type="string" default="">
<cfargument name="lOutputFields" type="string" default="">
<cfargument name="lUsersPermitted" type="string" default="">
<cfargument name="sUdfName" type="string" default="SQL">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName )>

<cfset structAppend( arguments, this.stDefaults, false )>

<!--- New buffer for sproc --->
<cfset this.addBuffer( arguments.sSprocName, "sql", true )>

<!--- Remove an existing sproc --->
<cfset this.appendDropSproc( arguments.sSprocName )>
<cfset this.appendSetOptions()>

<!--- Build the comments --->
<cfset this.appendBlank()>
<cfset this.appendDivide()>
<cfset this.appendCommentLine( "Execute arbitrary SQL code" )>
<cfset this.appendCommentLine( "based on fields: #replace( arguments.lFilterFields, ',', ', ', 'all' )#" )>
<cfif len( arguments.lUsersPermitted )>
	<cfset this.appendCommentLine( "Accessible to: #replace( arguments.lUsersPermitted, ',', ', ', 'all' )#" )>
</cfif>
<cfset this.appendDivide()>
<cfset this.appendBlank()>

<!--- Here is the meat and bones of it all --->
<cfset this.appendCreateSproc( arguments.sSprocName )>
<cfset this.appendParamFields( qMetadata, arguments.lParamFields, arguments.lOutputFields, false )>
<cfset this.append( "AS" )>
<cfset this.appendBegin()>
	<cfset this.appendNoCount()>
	
	<cfset this.appendVar( "error", "int", "0", "Add a safe place to hold errors" )>
	<cfset this.appendVar( "spname", "sysname", "Object_Name(@@ProcID)", "Store this sproc's name" )>
	
	<cfif arguments.bErrorCheck>
		<cfset this.appendMakeNullFields( qMetadata, arguments.lFilterFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
		<cfset this.appendCheckFields( qMetadata, arguments.lFilterFields, arguments.bUseDefaults )>
		<cfset this.appendBlank()>
	</cfif>
	
	<cfset this.appendComment( "Finally grab the records we want" )>
	<cfset this.append( attributes.sSql )>
	
	<cfif arguments.bErrorCheck>
		<cfset this.appendBlank()>
		<cfset this.appendErrorCheck()>
	</cfif>
	
<cfset this.appendEnd()>
<cfset this.append( "GO" )>
<cfset this.appendBlank()>
<cfset this.appendGrantObject( arguments.sSprocName, arguments.lUsersPermitted )>

<cfset arguments.qFields = qMetadata>
<cfset arguments.lInputFields = udf.listRemoveListNoCase( arguments.lParamFields, arguments.lOutputFields )>

<!--- Store Param definition --->
<cfset this.addDefinition( "sql", arguments, this.readBuffer( arguments.sSprocName ) )>

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