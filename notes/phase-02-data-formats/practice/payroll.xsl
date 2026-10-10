<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <payroll>
      <xsl:for-each select="employees/employee">
        <worker>
          <empId><xsl:value-of select="@id"/></empId>
          <fullName><xsl:value-of select="name"/></fullName>
          <xsl:choose>
            <xsl:when test="salary &gt; 50000"><band>Senior</band></xsl:when>
            <xsl:otherwise><band>Junior</band></xsl:otherwise>
          </xsl:choose>
        </worker>
      </xsl:for-each>
    </payroll>
  </xsl:template>
</xsl:stylesheet>
