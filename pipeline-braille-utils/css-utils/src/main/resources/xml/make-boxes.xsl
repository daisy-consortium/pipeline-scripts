<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                exclude-result-prefixes="#all"
                version="2.0">
    
    <xsl:include href="library.xsl"/>
    
    <xsl:template match="/*" priority="1">
        <css:root>
            <xsl:next-match/>
        </css:root>
    </xsl:template>
    
    <xsl:template match="*[@css:display]">
        <xsl:choose>
            <xsl:when test="@css:display='none'">
                <xsl:element name="css:_">
                    <xsl:if test="descendant-or-self::*[@css:string-set]">
                        <xsl:attribute name="css:string-set"
                                       select="string-join(descendant-or-self::*/@css:string-set/string(.), ', ')"/>
                    </xsl:if>
                    <xsl:if test="descendant-or-self::*[@css:counter-reset]">
                        <xsl:attribute name="css:counter-reset"
                                       select="string-join(descendant-or-self::*/@css:counter-reset/string(.), ' ')"/>
                    </xsl:if>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="css:box">
                    <xsl:attribute name="type" select="if (@css:display=('block','list-item')) then 'block' else 'inline'"/>
                    <xsl:attribute name="name" select="name()"/>
                    <xsl:apply-templates select="@style|@css:*"/>
                    <xsl:if test="@css:display='list-item'">
                        <!--
                            implied by display: list-item
                        -->
                        <xsl:attribute name="css:counter-increment" select="'list-item'"/>
                        <xsl:variable name="list-style-type" as="xs:string"
                                      select="css:specified-properties('list-style-type', true(), true(), true(), .)/@value"/>
                        <xsl:if test="$list-style-type!='none'">
                            <css:box type="inline" name="css:marker">
                                <css:counter name="list-item" style="{$list-style-type}"/>
                            </css:box>
                        </xsl:if>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="css:string|css:counter|css:text|css:leader|css:white-space">
        <xsl:sequence select="."/>
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:element name="css:box">
            <xsl:attribute name="type" select="'inline'"/>
            <xsl:attribute name="name" select="name()"/>
            <xsl:apply-templates select="@style|@css:*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@css:display|@css:list-style-type"/>
    
    <xsl:template match="@*|text()">
        <xsl:sequence select="."/>
    </xsl:template>
    
</xsl:stylesheet>