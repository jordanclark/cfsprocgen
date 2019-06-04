
<cffunction name="appendGrantObject" access="package" output="false">

<cfargument name="sSprocName" type="string" required="true">
<cfargument name="lUsersPermitted" type="string" default="">

<cfset var sUser = "">

<cfif len( arguments.lUsersPermitted )>
	<cfset this.appendComment( "Grant permission to the priviledged users" )>
	<cfloop index="sUser" list="#arguments.lUsersPermitted#">		
		<cfset this.append( "IF EXISTS ( SELECT * FROM master.dbo.syslogins WHERE ( loginname = '#sUser#' ) )" )>
		<cfset this.indent()>
		<cfset this.append( "GRANT EXECUTE ON #this.owner#.#this.getSqlSafeName( arguments.sSprocName )# TO #sUser#" )>
		<cfset this.unindent()>
	</cfloop>
	<cfset this.append( "GO" )>
</cfif>

<cfreturn>

</cffunction>