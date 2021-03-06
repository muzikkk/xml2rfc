<!--
    Augment section links to RFCs and Internet Drafts, also cleanup 
    unneeded markup from kramdown2629

    Copyright (c) 2017, Julian Reschke (julian.reschke@greenbytes.de)
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Neither the name of Julian Reschke nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
-->

<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               version="2.0"
               xmlns:x="http://purl.org/net/xml2rfc/ext"
>

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no" doctype-system=""/>

<!-- white-space separated list of specs which should be linked directly to -->
<xsl:param name="sibling-specs"/>

<!-- URI template for feedback, as described in https://www.greenbytes.de/tech/webdav/rfc2629xslt/rfc2629xslt.html#ext.element.feedback -->
<xsl:param name="feedback"/>

<xsl:template match="/">
  <xsl:variable name="t1">
    <xsl:apply-templates mode="insert-refs"/>
  </xsl:variable>
  <xsl:variable name="t2">
    <xsl:for-each select="$t1">
      <xsl:apply-templates mode="strip-refs"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="t3">
    <xsl:for-each select="$t2">
      <xsl:apply-templates mode="remove-kramdownleftovers"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="t4">
    <xsl:for-each select="$t3">
      <xsl:apply-templates mode="link-sibling-specs"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="t5">
    <xsl:for-each select="$t4">
      <xsl:apply-templates mode="insert-feedback"/>
    </xsl:for-each>
  </xsl:variable>
  <xsl:for-each select="$t5">
    <xsl:apply-templates mode="insert-prettyprint"/>
  </xsl:for-each>
</xsl:template>

<xsl:template match="*|@*|comment()|processing-instruction()">
  <xsl:copy><xsl:apply-templates select="node()|@*"/></xsl:copy>
</xsl:template>

<xsl:template match="rfc" mode="insert-refs">
  <rfc xmlns:x="http://purl.org/net/xml2rfc/ext">
    <xsl:apply-templates select="node()|@*" mode="insert-refs"/>
  </rfc>
</xsl:template>

<xsl:template match="*|@*|comment()|processing-instruction()" mode="insert-refs">
  <xsl:copy><xsl:apply-templates select="node()|@*" mode="insert-refs"/></xsl:copy>
</xsl:template>

<xsl:template match="text()" mode="insert-refs">
  <xsl:variable name="ts" select="following-sibling::*[1]"/>
  <xsl:variable name="s" select="$ts[self::xref and not(text()) and (not(@format) or @format='default') and //reference[@anchor=$ts/@target]]"/>
  <xsl:variable name="tp" select="preceding-sibling::*[1]"/>
  <xsl:variable name="p" select="$tp[self::xref and not(text()) and (not(@format) or @format='default') and //reference[@anchor=$tp/@target]]"/>
  <xsl:variable name="secnum">([0-9A-Z](\.[0-9A-Z])*)</xsl:variable>
  <xsl:variable name="sp">(.*)(Section|Appendix)\s+(<xsl:value-of select="$secnum"/>*)\s+of\s*$</xsl:variable>
  <xsl:variable name="pp">^,\s+(Section|Appendix)\s+(<xsl:value-of select="$secnum"/>*)(.*)</xsl:variable>
  <xsl:variable name="bad1">^\s+(Section|Appendix)\s+(<xsl:value-of select="$secnum"/>*)(.*)</xsl:variable>
  <xsl:variable name="bad2">^;\s+(Section|Appendix)\s+(<xsl:value-of select="$secnum"/>*)(.*)</xsl:variable>
  <xsl:choose>
    <xsl:when test="$s and matches(., $sp,'s')">
      <xsl:variable name="reftarget" select="//reference[@anchor=$s/@target]"/>
      <xsl:choose>
        <xsl:when test="$reftarget and $reftarget[seriesInfo/@name='RFC' or seriesInfo/@name='Internet-Draft']">
          <xsl:value-of select="replace(., $sp, '$1', 's')"/><xref INSERT="following" target="{$s/@target}" x:fmt="of" x:sec="{replace(., $sp, '$3', 's')}"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$p and matches(., $pp,'s')">
      <xsl:variable name="reftarget" select="//reference[@anchor=$p/@target]"/>
      <xsl:choose>
        <xsl:when test="$reftarget and $reftarget[seriesInfo/@name='RFC' or seriesInfo/@name='Internet-Draft']">
          <xref INSERT="preceding" target="{$p/@target}" x:fmt="," x:sec="{replace(., $pp, '$2', 's')}"/><xsl:value-of select="replace(., $pp, '$5', 's')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$p and matches(., $bad1,'s')">
      <xsl:variable name="reftarget" select="//reference[@anchor=$p/@target]"/>
      <xsl:choose>
        <xsl:when test="$reftarget and $reftarget[seriesInfo/@name='RFC' or seriesInfo/@name='Internet-Draft']">
          <xsl:message>INFO: weirdly formatted section xref to <xsl:value-of select="$p/@target"/>: <xsl:value-of select="replace(., $bad1, '$2', 's')"/>, converting anyway</xsl:message>
          <xref target="{$p/@target}" x:fmt="sec" x:sec="{replace(., $bad1, '$2', 's')}"/><xsl:value-of select="replace(., $bad1, '$5', 's')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="$p and matches(., $bad2,'s')">
      <xsl:variable name="reftarget" select="//reference[@anchor=$p/@target]"/>
      <xsl:choose>
        <xsl:when test="$reftarget and $reftarget[seriesInfo/@name='RFC' or seriesInfo/@name='Internet-Draft']">
          <xsl:message>INFO: weirdly formatted section xref to <xsl:value-of select="$p/@target"/>: <xsl:value-of select="replace(., $bad2, '$2', 's')"/>, converting anyway</xsl:message>
          <xsl:text>; </xsl:text><xref target="{$p/@target}" x:fmt="sec" x:sec="{replace(., $bad2, '$2', 's')}"/><xsl:value-of select="replace(., $bad2, '$5', 's')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="."/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="*|@*|comment()|processing-instruction()" mode="strip-refs">
  <xsl:copy><xsl:apply-templates select="node()|@*" mode="strip-refs"/></xsl:copy>
</xsl:template>

<xsl:template match="xref[not(node())]" mode="strip-refs">
  <xsl:variable name="fx" select="following-sibling::*[1]"/>
  <xsl:variable name="f" select="$fx[self::xref and @INSERT='preceding']"/>
  <xsl:variable name="px" select="preceding-sibling::*[1]"/>
  <xsl:variable name="p" select="$px[self::xref and @INSERT='following']"/>
  <xsl:choose>
    <xsl:when test="$f or $p"/>
    <xsl:otherwise>
      <xsl:copy><xsl:apply-templates select="node()|@*" mode="strip-refs"/></xsl:copy>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="xref/@INSERT" mode="strip-refs"/>

<xsl:template match="*|@*|comment()|processing-instruction()" mode="remove-kramdownleftovers">
  <xsl:copy><xsl:apply-templates select="node()|@*" mode="remove-kramdownleftovers"/></xsl:copy>
</xsl:template>

<xsl:template match="artwork/@align[.='left']" mode="remove-kramdownleftovers"/>
<xsl:template match="artwork/@alt[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="artwork/@height[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="artwork/@name[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="artwork/@type[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="artwork/@width[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="artwork/@xml:space[.='preserve']" mode="remove-kramdownleftovers"/>
<xsl:template match="comment()[contains(.,'markdown-source')]" mode="remove-kramdownleftovers"/>
<xsl:template match="figure/@align[.='left']" mode="remove-kramdownleftovers"/>
<xsl:template match="figure/@alt[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="figure/@height[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="figure/@suppress-title[.='false']" mode="remove-kramdownleftovers"/>
<xsl:template match="figure/@title[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="figure/@width[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="organization[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="rfc/@obsoletes[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="rfc/@updates[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="rfc/@xml:lang[.='en']" mode="remove-kramdownleftovers"/>
<xsl:template match="reference/front/abstract" mode="remove-kramdownleftovers"/>
<xsl:template match="reference/format" mode="remove-kramdownleftovers"/>
<xsl:template match="section/@toc[.='default']" mode="remove-kramdownleftovers"/>
<xsl:template match="spanx/@style[.='emph']" mode="remove-kramdownleftovers"/>
<xsl:template match="spanx/@xml:space[.='preserve']" mode="remove-kramdownleftovers"/>
<xsl:template match="texttable/@align[.='center']" mode="remove-kramdownleftovers"/>
<xsl:template match="texttable/@style[.='full']" mode="remove-kramdownleftovers"/>
<xsl:template match="texttable/@suppress-title[.='false']" mode="remove-kramdownleftovers"/>
<xsl:template match="texttable/@title[.='']" mode="remove-kramdownleftovers"/>
<xsl:template match="xref/@format[.='default']" mode="remove-kramdownleftovers"/>
<xsl:template match="xref/@pageno[.='false']" mode="remove-kramdownleftovers"/>

<xsl:template match="reference[seriesInfo/@name='RFC']/@target[starts-with(.,'http://www.rfc-editor.org/info/') or starts-with(.,'https://www.rfc-editor.org/info/')]" mode="remove-kramdownleftovers">
  <xsl:variable name="rsi" select="../seriesInfo[@name='RFC']"/>
  <xsl:variable name="no" select="$rsi/@value"/>
  <xsl:if test=". != concat('http://www.rfc-editor.org/info/rfc',$no) and . != concat('https://www.rfc-editor.org/info/rfc',$no)">
    <xsl:copy/>
  </xsl:if>
</xsl:template>

<xsl:template match="*|@*|comment()|processing-instruction()" mode="link-sibling-specs">
  <xsl:copy><xsl:apply-templates select="node()|@*" mode="link-sibling-specs"/></xsl:copy>
</xsl:template>

<xsl:template match="reference" mode="link-sibling-specs">
  <xsl:copy>
    <xsl:apply-templates select="node()|@*" mode="link-sibling-specs"/>
    <xsl:variable name="draftName" select="normalize-space(seriesInfo[@name='Internet-Draft']/@value)"/>
    <xsl:if test="not(x:source) and $draftName!='' and contains(concat(' ',normalize-space($sibling-specs),' '), $draftName)">
      <x:source href="{$draftName}.xml" basename="{$draftName}"/>
    </xsl:if>
  </xsl:copy>
</xsl:template>

<xsl:template match="*|@*|comment()|processing-instruction()" mode="insert-feedback">
  <xsl:copy><xsl:apply-templates select="node()|@*" mode="insert-feedback"/></xsl:copy>
</xsl:template>

<xsl:template match="rfc" mode="insert-feedback">
  <xsl:copy>
    <xsl:apply-templates select="@*" mode="insert-feedback"/>
    <xsl:if test="$feedback!='' and not(x:feedback)">
      <x:feedback template="{$feedback}"/>
    </xsl:if>
    <xsl:apply-templates select="node()" mode="insert-feedback"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="*|@*|comment()|processing-instruction()" mode="insert-prettyprint">
  <xsl:copy><xsl:apply-templates select="node()|@*" mode="insert-prettyprint"/></xsl:copy>
</xsl:template>

<xsl:template match="rfc" mode="insert-prettyprint">
  <xsl:processing-instruction name="rfc-ext">html-pretty-print="prettyprint https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js"</xsl:processing-instruction>
  <xsl:text>&#10;</xsl:text>
  <xsl:copy-of select="."/>
</xsl:template>

</xsl:transform>

