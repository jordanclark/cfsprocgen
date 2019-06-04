
<cffunction name="selectRecordSproc" output="false" returnType="string">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.selectRecordSuffix#">
<cfargument name="lFilterFields" type="string" default="!PK">
<cfargument name="lSelectFields" type="string" default="*">
<cfargument name="sOrderBy" type="string" default="">
<cfargument name="nTopRows" type="numeric" default="-1">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="#this.selectRecordSuffix#">

<cfset arguments.bSearchFields = false>

<cfreturn this.selectSproc( argumentcollection = arguments )>

</cffunction>