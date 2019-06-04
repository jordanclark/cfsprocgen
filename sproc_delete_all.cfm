
<cffunction name="deleteAllSproc" access="package" output="false" returnType="string">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.deleteAllSuffix#">
<cfargument name="bErrorCheck" type="boolean" default="true">
<cfargument name="lUsersPermitted" type="string" required="false">
<cfargument name="sUdfName" type="string" default="#this.deleteAllSuffix#">

<cfset arguments.lFilterFields = "!PK">

<cfreturn this.deleteSproc( argumentCollection = arguments )>

</cffunction>