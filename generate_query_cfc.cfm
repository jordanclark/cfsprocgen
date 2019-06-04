
<cffunction name="generateQueryCFC" output="false" returnType="string">

<cfargument name="stDef" type="struct" required="true">

<cfset var sCFMLCode = "">
<cfset var sItem = "">

<cf_save_content variable="sCFMLCode" unindent="2"><cfoutput>
<cfif listFindNoCase( "select,selectSet", stDef.sType )>
-	{{cffunction name="#stDef.stArgs.sSprocName#" output="false" returnType="query"}}
<cfelse>
-	{{cffunction name="#stDef.stArgs.sSprocName#" output="false" returnType="numeric"}}
</cfif>
#this.sNewLine#

<cfloop index="sItem" list="#stDef.stArgs.lParamFields#">
^	{{cfargument
^		 name="#sItem#"
^		 type="#stDef.stFields[ sItem ].cftype#"
^		 default="#stDef.stFields[ sItem ].default#"
^	{{#this.sNewLine#
</cfloop>
<cfif listFindNoCase( "select,selectSet", stDef.sType )>
^	{{cfargument name="maxRows" type="numeric" default="-1"}}#this.sNewLine#
</cfif>

{{cfstoredproc
^	 procedure="#this.owner#.#stDef.stArgs.sSprocName#<cfif structKeyExists( stDef.stArgs, "sSet" )>##arguments.selectSet##</cfif>"
^	 dataSource="#stDef.stArgs.sDSN#" returnCode="true"}}
<cfloop index="sItem" list="#stDef.stArgs.lParamFields#">#this.sTab#
^	{{cfprocparam
^		 type="#stDef.stFields[ sItem ].type#"
^		 dbVarName="#stDef.stFields[ sItem ].varName#"
^		<cfif findNoCase( "OUT", stDef.stFields[ sItem ].type )> variable="arguments.#sItem#"</cfif>
^		<cfif findNoCase( "IN", stDef.stFields[ sItem ].type )> value="##arguments.#sItem###"</cfif>
^		 cfSqlType="#stDef.stFields[ sItem ].cfSqlType#"
^		<cfif len( stDef.stFields[ sItem ].maxLength )> maxLength="#stDef.stFields[ sItem ].maxLength#"</cfif>
^		<cfif len( stDef.stFields[ sItem ].scale )> scale="#stDef.stFields[ sItem ].scale#"</cfif>
^		 null="<cfif stDef.stFields[ sItem ].nullable OR len( stDef.stFields[ sItem ].default )>##( NOT len( arguments.#sItem# ) ? true : false )##<cfelse>false</cfif>"
^	 /}}
</cfloop>
<cfif listFindNoCase( "select,selectSet", stDef.sType )>#this.sTab#
^	{{cfprocresult
^		 name="#stDef.stArgs.sQueryName#"
^		 resultSet="1"
^		 maxRows="##arguments.maxrows##"
^	}}
</cfif>
^{{/cfstoredproc}}

<cfif listFindNoCase( "select,selectSet", stDef.sType )>
-	{{cfreturn #stDef.stArgs.sQueryName#}}
<cfelseif stDef.sType IS "count">
-	{{cfreturn arguments.count}}
<cfelseif stDef.sType IS "exists">
-	{{cfreturn arguments.exists}}
<cfelse><!--- save,insert,update --->
-	{{cfreturn}}
</cfif>

{{!--- Actual Stored Procedure T-SQL Code
#stDef.sSql#
---}}

{/cffunction}
</cfoutput></cf_save_content>

<cfset sCFMLCode = replaceList( sCFMLCode, "{{,}}", "<,>" ) />
<!--- <cfset sCFMLCode = reReplace( sCFMLCode, "(#chr( 10 )#|#chr( 13 )#)(#chr( 9 )#)*(#chr( 10 )#|#chr( 13 )#)", "\1", "all" )> --->
<cfset sCFMLCode = reReplace( sCFMLCode, "(#chr( 10 )#|#chr( 13 )#)\^(#chr( 9 )#)*", "", "all" )>
<!--- <cfset sCFMLCode = reReplace( sCFMLCode, "(#chr( 10 )#|#chr( 13 )#)-(#chr( 9 )#)+", "\1", "all" )>
<cfset sCFMLCode = reReplace( sCFMLCode, "( ){2,}", " ", "all" )>
<cfset sCFMLCode = reReplace( sCFMLCode, "(#chr( 10 )##chr( 13 )#)+", "#chr( 10 )##chr( 13 )#", "all" )> --->

<cfreturn sCFMLCode>

</cffunction>