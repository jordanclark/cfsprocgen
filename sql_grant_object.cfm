
<cffunction name="appendGrantObject" access="package" output="false">

<cfargument name="sSprocName" type="string" required="true">
<cfargument name="lUsersPermitted" type="string" default="">

<cfset arguments.lUsersPermitted = replace( arguments.lUsersPermitted, ",", ", ", "all" )>

<cfif len( arguments.lUsersPermitted )>
	<cfset this.appendComment( "Grant permission to the priviledged users" )>
	<cfset this.append( "GRANT EXECUTE ON #this.owner#.#this.getSqlSafeName( arguments.sSprocName )# TO #arguments.lUsersPermitted#" )>
	<cfset this.append( "GO" )>
</cfif>

<cfreturn>

</cffunction>