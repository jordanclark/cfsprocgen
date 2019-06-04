
<cffunction name="appendSetOptions" access="package" output="false">

<cfset this.append( "SET CONCAT_NULL_YIELDS_NULL OFF" )>
<cfset this.append( "SET QUOTED_IDENTIFIER OFF" )>
<cfset this.append( "SET ANSI_NULLS OFF" )> 
<cfset this.append( "SET NOCOUNT ON" )>
<cfset this.append( "GO" )>

<cfreturn>

</cffunction>