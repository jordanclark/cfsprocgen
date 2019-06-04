
<cffunction name="writeDefinition" output="false">

<cfargument name="lSprocDefs" type="string" required="true">
<cfargument name="sFileName" type="string" required="true">
<cfargument name="sType" type="string" required="true">
<cfargument name="sComponent" type="string" default="">

<cfset var sOutput = "">		
<cfset var sSproc = "">
<cfset var stDef = "">

<cfswitch expression="#arguments.sType#">

	<cfcase value="CFC">
		<cfif len( arguments.sComponent )>
			<cfset sOutput = sOutput & '<cfcomponent displayname="#arguments.sComponent#" output="false">' & this.sNewLine />
		</cfif>
		<cfloop index="sSproc" list="#arguments.lSprocDefs#">
			<cfset stDef = this.stDefinitions[ sSproc ]>
			<cfset stDef.stArgs.sFilename = arguments.sFilename>
			<cfset sOutput = sOutput & this.generateQueryCFC( stDef )>
		</cfloop>
		<cfif len( arguments.sComponent )>
			<cfset sOutput = sOutput & this.sNewLine & '</cfcomponent>' />
		</cfif>
	</cfcase>
	
	<cfcase value="CFTAG">
		<cfset stDef = this.stDefinitions[ listFirst( arguments.lSprocDefs ) ]>
		<cfset stDef.stArgs.sFilename = arguments.sFilename>
		<cfset sOutput = this.generateQueryTag( stDef )>
	</cfcase>

</cfswitch>

<cfset sOutput = trim( replaceList( htmlEditFormat( sOutput, -1 ), '&lt;,&gt;,&quot;,&amp;', '<,>,",&' ) ) />

<!--- <cfoutput>#htmlCodeFormat( sOutput )#</cfoutput> --->

<cfif NOT directoryExists( getDirectoryFromPath( arguments.sFileName ) )>
	<cfset directoryCreate( getDirectoryFromPath( arguments.sFileName ), true, true )>
</cfif>

<cfset fileWrite( arguments.sFileName, sOutput )>

<cfreturn>

</cffunction>