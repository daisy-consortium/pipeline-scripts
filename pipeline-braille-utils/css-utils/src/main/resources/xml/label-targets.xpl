<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                type="css:label-targets"
                exclude-inline-prefixes="#all"
                version="1.0">
    
    <!--
        Add a @css:id attribute to elements that are references by a target-text, target-string
        or target-counter function. No two elements will get the same @css:id.
    -->
    
    <p:input port="source" sequence="true"/>
    <p:output port="result" sequence="true"/>
    
    <p:wrap-sequence wrapper="_"/>
    
    <p:xslt>
        <p:input port="stylesheet">
            <p:document href="label-targets.xsl"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
    </p:xslt>
    
    <p:delete match="@css:id[string(.)=parent::*/(ancestor::*|preceding::*)/@css:id/string()]"/>
    
    <p:filter select="/_/*"/>
    
</p:declare-step>