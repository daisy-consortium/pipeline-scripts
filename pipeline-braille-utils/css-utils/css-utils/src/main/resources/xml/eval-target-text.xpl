<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                type="css:eval-target-text"
                exclude-inline-prefixes="#all"
                version="1.0">
    
    <p:documentation>
        Evaluate target-text() values.
    </p:documentation>
    
    <p:input port="source" sequence="true">
        <p:documentation>
            target-text() values in the input must be represented by css:text elements. Elements
            that are referenced by a target-text() value must be indicated with a css:id attribute
            that matches the css:text element's target attribute.
        </p:documentation>
    </p:input>
    
    <p:output port="result" sequence="true">
        <p:documentation>
            css:text elements are replaced by the string value of their target element (the element
            whose css:id attribute corresponds with the css:text element's target attribute) and
            wrapped in an inline css:box element with a css:anchor attribute that matches the xml:id
            attribute of the target element.
        </p:documentation>
    </p:output>
    
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
    
    <p:wrap-sequence wrapper="css:_"/>
    
    <px:message message="[progress css:eval-target-text 100 eval-target-text.xsl]"/>
    <p:xslt>
        <p:input port="stylesheet">
            <p:document href="eval-target-text.xsl"/>
        </p:input>
        <p:input port="parameters">
            <p:empty/>
        </p:input>
    </p:xslt>
    
    <p:filter select="/css:_/*"/>
    
</p:declare-step>