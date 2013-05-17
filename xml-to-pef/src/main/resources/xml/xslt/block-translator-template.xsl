<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
	xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
	exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css/xslt/parsing-helper.xsl"/>
	
	<xsl:template match="css:block">
		<xsl:param name="context" as="element()"/>
		<xsl:apply-templates select="node()">
			<xsl:with-param name="context" select="$context"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="/">
		<xsl:apply-templates select="*" mode="identify-blocks"/>
	</xsl:template>
	
	<xsl:template match="*" mode="identify-blocks">
		<xsl:param name="parent-is-block" as="xs:boolean" select="true()"/>
		<xsl:param name="parent-has-string-set" as="xs:boolean" select="true()"/>
		<xsl:param name="parent-display" as="xs:string" select="'block'"/>
		<xsl:variable name="is-block" as="xs:boolean" select="$parent-is-block and pxi:is-block(.)"/>
		<xsl:variable name="has-string-set" as="xs:boolean" select="$parent-has-string-set and pxi:has-string-set(.)"/>
		<xsl:variable name="string-set" as="xs:string" select="if ($has-string-set) then pxi:string-set(.) else 'none'"/>
		<xsl:variable name="display" as="xs:string" select="if ($parent-display='none') then 'none' else pxi:display(.)"/>
		<xsl:variable name="this" as="element()" select="."/>
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$string-set!='none'">
					<xsl:variable name="string-set-result" as="xs:string*">
						<xsl:for-each select="tokenize($string-set,',')">
							<xsl:variable name="identifier" select="replace(., '^\s*(\S+)\s.*$', '$1')"/>
							<xsl:variable name="content-list" select="substring-after(., $identifier)"/>
							<xsl:variable name="content" select="css:eval-content-list($this, $content-list)"/>
							<xsl:if test="exists($content) and matches($identifier, $IDENT)">
								<xsl:variable name="block">
									<xsl:element name="css:string-set">
										<xsl:attribute name="name" select="$identifier"/>
										<xsl:element name="css:block">
											<xsl:attribute name="xml:lang" select="pxi:lang($this)"/>
											<xsl:sequence select="$content"/>
										</xsl:element>
									</xsl:element>
								</xsl:variable>
								<xsl:variable name="block-result">
									<xsl:apply-templates select="$block/css:string-set/css:block">
										<xsl:with-param name="context" select="$this"/>
									</xsl:apply-templates>
								</xsl:variable>
								<xsl:if test="normalize-space(string($block-result))">
									<xsl:sequence select="concat($identifier, ' &quot;', normalize-space(string($block-result)), '&quot;')"/>
								</xsl:if>
							</xsl:if>
						</xsl:for-each>
					</xsl:variable>
					<xsl:apply-templates select="@*[not(name()='style')]" mode="identify-blocks"/>
					<xsl:attribute name="style" select="concat(
						css:remove-from-style(string(@style), ('string-set')), ';string-set:', string-join($string-set-result,','))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@*" mode="identify-blocks"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="$display='none'">
					<xsl:if test="$has-string-set">
						<xsl:apply-templates select="*" mode="identify-blocks">
							<xsl:with-param name="parent-is-block" select="$is-block"/>
							<xsl:with-param name="parent-has-string-set" select="$has-string-set"/>
							<xsl:with-param name="parent-display" select="$display"/>
						</xsl:apply-templates>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each-group select="*|text()" group-adjacent="pxi:is-block(.) or pxi:has-string-set(.)">
						<xsl:choose>
							<xsl:when test="current-grouping-key()">
								<xsl:for-each select="current-group()">
									<xsl:apply-templates select="." mode="identify-blocks">
										<xsl:with-param name="parent-is-block" select="$is-block"/>
										<xsl:with-param name="parent-has-string-set" select="$has-string-set"/>
										<xsl:with-param name="parent-display" select="$display"/>
									</xsl:apply-templates>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="normalize-space(string-join(current-group()/string(.), ''))=''"/>
							<xsl:otherwise>
								<xsl:variable name="block">
									<xsl:element name="css:block">
										<xsl:attribute name="xml:lang" select="pxi:lang($this)"/>
										<xsl:variable name="inline-style" as="xs:string"
											select="string-join(
											(for $name in $properties[not(.='display')][css:applies-to(., 'inline')] return
												(for $value in css:get-property-value($this, $name, true(), false(), false()) return
													concat($name, ':', $value))), ';')"/>
										<xsl:if test="$inline-style!=''">
											<xsl:attribute name="style" select="$inline-style"/>
										</xsl:if>
										<xsl:for-each select="current-group()">
											<xsl:sequence select="."/>
										</xsl:for-each>
									</xsl:element>
								</xsl:variable>
								<xsl:apply-templates select="$block/css:block">
									<xsl:with-param name="context" select="$this"/>
								</xsl:apply-templates>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each-group>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*|text()" mode="identify-blocks">
		<xsl:copy/>
	</xsl:template>
	
	<xsl:function name="pxi:lang" as="xs:string">
		<xsl:param name="element" as="element()"/>
		<xsl:sequence select="$element/ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
	</xsl:function>
	
	<xsl:function name="pxi:display" as="xs:string">
		<xsl:param name="element" as="element()"/>
		<xsl:sequence select="css:get-property-value($element, 'display', true(), true(), false())"/>
	</xsl:function>
	
	<xsl:function name="pxi:string-set" as="xs:string">
		<xsl:param name="element" as="element()"/>
		<xsl:sequence select="css:get-property-value($element, 'string-set', true(), true(), false())"/>
	</xsl:function>
	
	<xsl:function name="pxi:is-block" as="xs:boolean">
		<xsl:param name="node" as="node()"/>
		<xsl:sequence select="boolean($node/descendant-or-self::*[pxi:display(.) != 'inline'])"/>
	</xsl:function>
	
	<xsl:function name="pxi:has-string-set" as="xs:boolean">
		<xsl:param name="node" as="node()"/>
		<xsl:sequence select="boolean($node/descendant-or-self::*[pxi:string-set(.) != 'none'])"/>
	</xsl:function>
	
</xsl:stylesheet>