<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
    xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
    xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal" type="pxi:html-to-epub3-content"
    version="1.0">

    <p:input port="html" sequence="true"/>
    <p:output port="docs" sequence="true" primary="true">
        <p:pipe port="result" step="docs"/>
    </p:output>
    <p:output port="fileset" primary="false">
        <p:pipe port="result" step="fileset"/>
    </p:output>


    <p:option name="publication-dir" required="true"/>
    <p:option name="content-dir" required="true"/>

    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/xproc/fileset-library.xpl"/>
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>


    <!--TODO if single doc, chunk; else keep original chunking-->


    <!--=========================================================================-->
    <!-- XHTML CLEANING                                                          -->
    <!--=========================================================================-->
    <p:group name="docs">
        <p:output port="result" sequence="true"/>
        <p:for-each>
            <p:variable name="original-uri" select="base-uri(/*)"/>
            
            
            <!--TODO remove http-equiv='content-type'-->

            <!--–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––>
             |   UPGRADE TO XHTML5                                                         |
            <|–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-->
            <p:xslt>
                <p:input port="stylesheet">
                    <p:document
                        href="http://www.daisy.org/pipeline/modules/html-utils/html5-upgrade.xsl"/>
                </p:input>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
            </p:xslt>

            <!--–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––>
             |   CLEAN HTTP-EQUIV                                                          |
            <|–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-->
            
            <p:delete match="/h:html/h:head/h:meta[matches(@http-equiv,'Content-Type','i')]" xmlns:h="http://www.w3.org/1999/xhtml"/>
            
            <!--–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––>
             |   FIX CONTENT MODELS                                                        |
            <|–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-->
            
            <p:xslt>
                <p:input port="stylesheet">
                    <p:document
                        href="http://www.daisy.org/pipeline/modules/html-utils/html-fixer.xsl"/>
                </p:input>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
            </p:xslt>
            
            <!--–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––>
             |   ADD MISSING IDS                                                           |
            <|–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-->
            <p:xslt>
                <p:input port="stylesheet">
                    <p:document
                        href="http://www.daisy.org/pipeline/modules/html-utils/html-id-fixer.xsl"/>
                </p:input>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
            </p:xslt>
            
            <!--–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––>
             |   CLEAN OUTLINE                                                        |
            <|–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-->

            <!--TODO: try to add sections where missing -->

            <!--–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––>
             |   CHANGE THE BASE URI TO A SAFE FILE NAME                                   |
            <|–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-->
            <p:identity name="html-final"/>
            <p:xslt name="safe-uri">
                <p:input port="stylesheet">
                    <p:inline>
                        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                            xmlns:f="http://www.daisy.org/ns/pipeline/internal-functions"
                            xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                            xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
                            <xsl:import
                                href="http://www.daisy.org/pipeline/modules/file-utils/xslt/uri-functions.xsl"/>
                            <xsl:template match="/">
                                <c:result><xsl:value-of
                                    select="pf:replace-path(base-uri(/*),escape-html-uri(replace(pf:unescape-uri(pf:get-path(base-uri(/*))),'[^\p{L}\p{N}\-/_.]','_')))"
                                /></c:result>
                            </xsl:template>
                        </xsl:stylesheet>
                    </p:inline>
                </p:input>
                <p:input port="parameters">
                    <p:empty/>
                </p:input>
            </p:xslt>
            <p:identity>
                <p:input port="source">
                    <p:pipe port="result" step="html-final"/>
                </p:input>
            </p:identity>
            <p:add-attribute match="/*" attribute-name="xml:base">
                <p:with-option name="attribute-value" select="resolve-uri(replace(normalize-space(.),'^.*?([^/]+)\.[^/]*$','$1.xhtml'), $content-dir)">
                    <p:pipe port="result" step="safe-uri"/>
                </p:with-option>
            </p:add-attribute>
            <p:delete match="/*/@xml:base"/>
            <!--<cx:message>
                <p:with-option name="message"
                    select="concat('upgraded HTML document to the EPUB3 content document ',substring($result-uri,string-length($publication-dir)+1))"
                />
            </cx:message>-->
        </p:for-each>
    </p:group>


    <!--=========================================================================-->
    <!-- RESULT FILESET                                                          -->
    <!--=========================================================================-->
    <p:group name="fileset">
        <p:output port="result"/>
        <p:for-each>
            <p:variable name="result-uri" select="base-uri(/*)"/>
            <px:fileset-create>
                <p:with-option name="base" select="$content-dir"/>
            </px:fileset-create>
            <px:fileset-add-entry media-type="application/xhtml+xml">
                <p:with-option name="href" select="$result-uri"/>
            </px:fileset-add-entry>
        </p:for-each>
        <px:fileset-join/>
    </p:group>


</p:declare-step>
