
<cffunction name="appendDropFunction" access="package" output="false">

<cfargument name="sName" type="string" required="true">

<cfset this.appendComment( "Drop the procedure if it already exists" )>
<cfset this.append( "IF EXISTS( SELECT * FROM sysobjects WHERE id = object_id(N'#sName#') and xtype in (N'FN', N'IF', N'TF')) )" )>
<cfset this.indent()>
<cfset this.append( "DROP FUNCTION #sName#" )>
<cfset this.unindent()>
<cfset this.append( "GO" )>

<cfreturn>

</cffunction>