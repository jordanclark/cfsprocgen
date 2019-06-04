
<cffunction name="selectAllSproc" output="false" returnType="string">

<cfargument name="sTableName" type="string" required="true">
<cfargument name="sSprocName" type="string" default="#arguments.sTableName##this.selectAllSuffix#">
<cfargument name="lUsersPermitted" type="string" default="">
<cfargument name="sUdfName" type="string" default="#this.selectAllSuffix#">

<cfset arguments.lFilterFields = "!PK">
<cfset arguments.lSelectFields = "*">

<cfreturn this.selectSproc( argumentcollection = arguments )>

</cffunction>