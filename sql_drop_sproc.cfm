
<cffunction name="appendDropSproc" access="package" output="false">

<cfargument name="sName" type="string" required="true">

<cfset this.appendComment( "Drop the procedure if it already exists" )>
<cfset this.append( "IF EXISTS( SELECT * FROM sysobjects WHERE name = '#sName#' ) BEGIN;" )>
<cfset this.indent()>
<cfset this.append( "DROP PROCEDURE #this.owner#.#this.getSqlSafeName( sName )#;" )>
<cfset this.unindent()>
<cfset this.append( "END;" )>
<cfset this.append( "GO" )>

<cfreturn>

</cffunction>