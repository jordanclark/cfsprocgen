
<cffunction name="selectSetSproc" output="true" returnType="string">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.selectSetSuffix#">
<cfargument name="lFilterFields" type="string" default="!PK">
<cfargument name="lSetSelectFields" type="string" required="true">
<cfargument name="sOrderBy" type="string" default="">
<cfargument name="nTopRows" type="numeric" default="-1">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="bSearchFields" type="boolean" default="false">
<cfargument name="lUsersPermitted" type="string" default="">
<cfargument name="sUdfName" type="string" default="#this.selectSetSuffix#">

<cfset var qMetadata = this.getTableMetadata( arguments.sTableName )>
<cfset var stArgs = {}>
<cfset var sOutput = "">
<cfset var nSetLength = listLen( arguments.lSetSelectFields, "|" )>
<cfset var nCurrentSet = 1>
<cfset var lSets = "">

<cfif left( arguments.sSprocName, len( this.sprocPrefix ) ) IS NOT this.sprocPrefix>
	<cfset arguments.sSprocName = this.sprocPrefix & this.camelCase( arguments.sSprocName )>
</cfif>
<cfset arguments.lSelectFields = "">
<cfset arguments.lOutputFields = "">

<cfset qMetadata= this.addColumnMetadataRow(
	qMetadata= qMetadata
,	sTypeName="int"
,	sColumnName="selectSet"
,	sDefaultValue="1"
,	bPrimaryKeyColumn="0"
,	isNullable="0"
,	isComputed="0"
,	isIdentity="0"
,	isSearchable="0"
)>
<cfset arguments.lParamFields = this.filterColumnList( qMetadata, arguments.lFilterFields )>

<cfif NOT listLen( arguments.lSetSelectFields )>
	<cfset request.log( "!!Error: No fields to filter by. [SelectSproc][#sTableName#]" )>
	<cfreturn>
	<cfthrow type="Custom.CFC.SprocGen.SelectSproc.NoSelectFields"
		message="No fields to select."
	>
</cfif>

<cfset arguments.nSetSelectLength = nSetLength>
<cfset arguments.sSetSelect = arguments.sSprocName>

<cfloop index="nCurrentSet" from="1" to="#nSetLength#">
	<cfset stArgs = duplicate( arguments )>
	<cfset stArgs.sSetSelect = arguments.sSprocName>
	<cfset stArgs.nSetSelectIndex = nCurrentSet>
	<cfset stArgs.sSprocName = arguments.sSprocName & nCurrentSet>
	<cfset stArgs.lSelectFields = listGetAt( arguments.lSetSelectFields, nCurrentSet, "|" )>
	<cfset structDelete( stArgs, "lSetSelectFields" )>
	<cfset structDelete( stArgs, "sQueryTagFileName" )>
	
	<cfset this.selectSproc( argumentcollection = stArgs )>
	<cfset sOutput = sOutput & this.readBuffer( stArgs.sSprocName )>
	<cfset lSets = listAppend( lSets, arguments.sSprocName & nCurrentSet )>
</cfloop>

<!--- <cfoutput>
	SetCOUNT: #SetCount# <br />
</cfoutput>
<cfabort> --->

<cfset arguments.lSetSelects = lSets>
<cfset arguments.qFields = qMetadata>
<cfset arguments.lSelectFields = "">
<cfset arguments.lInputFields = udf.listRemoveListNoCase( arguments.lParamFields, arguments.lOutputFields )>

<!--- Store Param definition --->
<cfset this.addDefinition( "selectSet", arguments, sOutput )>

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