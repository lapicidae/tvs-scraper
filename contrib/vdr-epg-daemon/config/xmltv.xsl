<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <!-- Parameter to control whether IMDB star-rating is used as a fallback for numrating -->
    <xsl:param name="useImdbFallbackForNumrating" select="'no'"/> <!-- Default is 'no' ('yes' to enable) -->

    <!-- Variable for loading the category mapping file -->
    <!-- Ensure that 'xmltv-category.xml' is in the same directory as this XSLT file -->
    <xsl:variable name="category_mapping" select="document('xmltv-category.xml')/mapping/categories/category"/>

    <xsl:template match="/tv">
        <tv>
            <!-- Copy all attributes of the original /tv-element -->
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="channel"/>
            <xsl:apply-templates select="programme"/>
        </tv>
    </xsl:template>

    <xsl:template match="channel">
        <channel>
            <xsl:attribute name="id">
                <xsl:value-of select="@id"/>
            </xsl:attribute>
            <display-name>
                <xsl:value-of select="display-name"/>
            </display-name>
        </channel>
    </xsl:template>

    <xsl:template match="programme">
        <event>
            <!-- Copy all attributes of the programme element (e.g., @start, @stop, @channel, @clumpidx) -->
            <xsl:apply-templates select="@*"/>

            <!-- Numeric event ID as attribute: 14-digit timestamp (YYYYMMDDhhmmss) -->
            <!-- This value is unique per channel in combination with channel ID in the database's primary key. -->
            <xsl:attribute name="eventid">
                <xsl:value-of select="substring(@start, 1, 14)"/>
            </xsl:attribute>

            <!-- Programme title -->
            <title>
                <xsl:value-of select="title"/>
            </title>

            <!-- Sub-title mapped to shorttext -->
            <xsl:if test="sub-title != ''">
                <shorttext>
                    <xsl:value-of select="sub-title"/>
                </shorttext>
            </xsl:if>

            <!-- Short description and long description based on the length of the <desc> elements -->
            <xsl:variable name="desc1-cleaned">
                <xsl:if test="desc[1]">
                    <xsl:call-template name="strip-html">
                        <xsl:with-param name="text" select="desc[1]"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="desc2-cleaned">
                <xsl:if test="desc[2]">
                    <xsl:call-template name="strip-html">
                        <xsl:with-param name="text" select="desc[2]"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:variable>

            <xsl:variable name="final_shortdescription">
                <xsl:choose>
                    <xsl:when test="count(desc) &gt; 1">
                        <!-- If there are two or more <desc> elements, take the shorter one for shortdescription -->
                        <xsl:if test="string-length(normalize-space($desc1-cleaned)) &lt;= string-length(normalize-space($desc2-cleaned))">
                            <xsl:value-of select="normalize-space(substring($desc1-cleaned, 1, 300))"/>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space($desc2-cleaned)) &lt; string-length(normalize-space($desc1-cleaned))">
                            <xsl:value-of select="normalize-space(substring($desc2-cleaned, 1, 300))"/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- No shortdescription if only one or no desc is present -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="string-length($final_shortdescription) &gt; 0">
                <shortdescription>
                    <xsl:value-of select="$final_shortdescription"/>
                </shortdescription>
            </xsl:if>

            <xsl:variable name="final_longdescription">
                <xsl:choose>
                    <xsl:when test="count(desc) &gt; 1">
                        <!-- If there are two or more <desc> elements, take the longer one for longdescription -->
                        <xsl:if test="string-length(normalize-space($desc1-cleaned)) &gt; string-length(normalize-space($desc2-cleaned))">
                            <xsl:value-of select="$desc1-cleaned"/>
                        </xsl:if>
                        <xsl:if test="string-length(normalize-space($desc2-cleaned)) &gt;= string-length(normalize-space($desc1-cleaned))">
                            <xsl:value-of select="$desc2-cleaned"/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="count(desc) = 1">
                        <!-- If only one <desc> element is present, take this for longdescription -->
                        <xsl:value-of select="$desc1-cleaned"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- If no <desc> element is present, longdescription remains empty -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="string-length($final_longdescription) &gt; 0">
                <longdescription>
                    <xsl:value-of select="$final_longdescription"/>
                </longdescription>
            </xsl:if>

            <!-- Credits mapping (director, actor, writer, etc.) -->
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'actor'"/>
                <xsl:with-param name="element_name" select="'actor'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'director'"/>
                <xsl:with-param name="element_name" select="'director'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'producer'"/>
                <xsl:with-param name="element_name" select="'producer'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'writer'"/>
                <xsl:with-param name="element_name" select="'screenplay'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'commentator'"/>
                <xsl:with-param name="element_name" select="'commentator'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'presenter'"/>
                <xsl:with-param name="element_name" select="'moderator'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'guest'"/>
                <xsl:with-param name="element_name" select="'guest'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'camera'"/>
                <xsl:with-param name="element_name" select="'camera'"/>
            </xsl:call-template>
            <xsl:call-template name="emit-credits">
                <xsl:with-param name="xpath_name" select="'composer'"/>
                <xsl:with-param name="element_name" select="'music'"/>
            </xsl:call-template>

            <!-- Date (year) -->
            <xsl:if test="date != ''">
                <year>
                    <xsl:value-of select="date"/>
                </year>
            </xsl:if>

            <!-- Category mapping is applied via the named template 'mapping' -->
            <!-- The 'category' element is always generated by the mapping template, even if defaulted to 'Sonstige' (Other) -->
            <xsl:call-template name="mapping">
                <xsl:with-param name="str" select="category" />
            </xsl:call-template>

            <!-- Original category is additionally mapped as Genre -->
            <genre>
                <xsl:value-of select="category"/>
            </genre>
            
            <!-- Country of origin -->
            <xsl:if test="country != ''">
                <country>
                    <xsl:value-of select="country"/>
                </country>
            </xsl:if>

            <!-- Rating: Mapped from 'Rating by Genre' review, with fallback to other text reviews, explicitly ignoring 'Tipp' source -->
            <xsl:variable name="final_rating">
                <xsl:variable name="rating_conclusion" select="review[@type='text' and @source='Rating Conclusion']"/>
                <xsl:variable name="rating_by_genre" select="review[@type='text' and @source='Rating by Genre']"/>
                <xsl:choose>
                    <xsl:when test="$rating_by_genre != ''">
                        <xsl:value-of select="$rating_by_genre"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Fallback to the first text review that is neither 'Rating Conclusion' nor 'Tipp' -->
                        <xsl:value-of select="review[@type='text'][not(@source='Rating Conclusion') and not(@source='Tipp')][1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="string-length($final_rating) &gt; 0">
                <rating>
                    <xsl:value-of select="$final_rating"/>
                </rating>
            </xsl:if>

            <!-- Text rating: Mapped from 'Rating Conclusion' review. It will be empty if not found. -->
            <xsl:variable name="final_txtrating">
                <xsl:variable name="rating_conclusion" select="review[@type='text' and @source='Rating Conclusion']"/>
                <xsl:if test="$rating_conclusion != ''">
                    <xsl:value-of select="$rating_conclusion"/>
                </xsl:if>
            </xsl:variable>
            <xsl:if test="string-length($final_txtrating) &gt; 0">
                <txtrating>
                    <xsl:value-of select="$final_txtrating"/>
                </txtrating>
            </xsl:if>

            <!-- Numeric rating: Complex calculation based on TVSpielfilm, IMDB, and Tipp presence -->
            <xsl:variable name="final_numrating">
                <xsl:variable name="tvspielfilm_raw_val" select="star-rating[@system='TVSpielfilm']/value"/>
                <xsl:variable name="imdb_raw_val" select="star-rating[@system='IMDB']/value"/>
                
                <xsl:variable name="tvspielfilm_num">
                    <xsl:variable name="normalized_tvspielfilm_val" select="normalize-space($tvspielfilm_raw_val)"/>
                    <xsl:if test="$normalized_tvspielfilm_val != '' and contains($normalized_tvspielfilm_val, '/')">
                        <xsl:value-of select="number(substring-before($normalized_tvspielfilm_val, '/'))"/>
                    </xsl:if>
                </xsl:variable>

                <xsl:variable name="imdb_rating">
                    <xsl:variable name="normalized_imdb_val" select="normalize-space(translate($imdb_raw_val, ',', '.'))"/>
                    <xsl:if test="$normalized_imdb_val != '' and contains($normalized_imdb_val, '/')">
                        <xsl:value-of select="number(substring-before($normalized_imdb_val, '/'))"/>
                    </xsl:if>
                </xsl:variable>

                <!-- TVSpielfilm base rating -->
                <xsl:variable name="tvspielfilm_base">
                    <xsl:if test="string-length($tvspielfilm_num) &gt; 0">
                        <xsl:value-of select="$tvspielfilm_num"/>
                    </xsl:if>
                </xsl:variable>

                <xsl:variable name="scaled_imdb_val">
                    <xsl:if test="string-length($imdb_rating) &gt; 0 and $imdb_rating &gt;= 1 and $imdb_rating &lt;= 10">
                        <xsl:value-of select="floor(1 + ($imdb_rating - 1) * 4 div 9 + 0.5)"/>
                    </xsl:if>
                </xsl:variable>

                <!-- Bonus if the IMDb rating is 8 or higher -->
                <xsl:variable name="bonus_from_imdb">
                    <xsl:choose>
                        <xsl:when test="string-length($imdb_rating) &gt; 0 and $imdb_rating &gt;= 8">1</xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- Bonus from 'Tipp' review source -->
                <xsl:variable name="bonus_from_tipp">
                    <xsl:choose>
                        <xsl:when test="review[@type='text' and @source='Tipp']">1</xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="string-length($tvspielfilm_num) &gt; 0">
                        <xsl:variable name="calculated_rating" select="number($tvspielfilm_base)"/>
                        <xsl:variable name="total_bonus" select="number($bonus_from_imdb) + number($bonus_from_tipp)"/>
                        <xsl:variable name="pre_final_rating" select="$calculated_rating + $total_bonus"/>

                        <xsl:choose>
                            <xsl:when test="number($pre_final_rating) &gt; 5">5</xsl:when>
                            <xsl:otherwise><xsl:value-of select="$pre_final_rating"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$useImdbFallbackForNumrating = 'yes' and string-length($imdb_rating) &gt; 0">
                        <xsl:value-of select="$scaled_imdb_val"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- If neither TVSpielfilm nor IMDB (if fallback disabled) is present, check for any other star-rating -->
                        <xsl:variable name="other_star_rating_raw">
                            <xsl:variable name="raw_val" select="star-rating[not(@system='TVSpielfilm') and not(@system='IMDB')][1]/value"/>
                            <xsl:value-of select="normalize-space($raw_val)"/>
                        </xsl:variable>
                        <xsl:if test="$other_star_rating_raw != '' and contains($other_star_rating_raw, '/')">
                            <xsl:value-of select="number(substring-before($other_star_rating_raw, '/'))"/>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="string-length($final_numrating) &gt; 0">
                <numrating>
                    <xsl:value-of select="$final_numrating"/>
                </numrating>
            </xsl:if>

            <!-- Parental rating: Extracts value from 'FSK' system or next available rating, ignoring zero values -->
            <xsl:variable name="fsk_val" select="rating[@system='FSK']/value"/>
            <xsl:variable name="other_rating_val" select="rating[not(@system='FSK')][1]/value"/>
            
            <xsl:variable name="raw_parental_candidate">
                <xsl:choose>
                    <xsl:when test="string-length($fsk_val) > 0">
                        <xsl:value-of select="$fsk_val"/>
                    </xsl:when>
                    <xsl:when test="string-length($other_rating_val) > 0">
                        <xsl:value-of select="$other_rating_val"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- No suitable rating found -->
                        <xsl:text></xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:variable name="numeric_parental_rating">
                <xsl:if test="string-length($raw_parental_candidate) > 0">
                    <xsl:variable name="num_val" select="number($raw_parental_candidate)"/>
                    <xsl:if test="not(string($num_val) = 'NaN')">
                        <xsl:value-of select="$num_val"/>
                    </xsl:if>
                </xsl:if>
            </xsl:variable>

            <xsl:if test="string-length($numeric_parental_rating) > 0 and number($numeric_parental_rating) != 0">
                <parentalrating>
                    <xsl:value-of select="number($numeric_parental_rating)"/>
                </parentalrating>
            </xsl:if>

            <!-- Tipp mapping: Mapped from 'Tipp' review source -->
            <xsl:if test="review[@type='text' and @source='Tipp']">
                <tipp>
                    <xsl:value-of select="review[@type='text' and @source='Tipp']"/>
                </tipp>
            </xsl:if>

            <!-- Placeholder for start time and duration. These are typically calculated by the epgd-plugin itself
                 from the @start and @stop attributes of the programme element and converted to its internal format.
                 Therefore, dummy values are provided here. -->
            <starttime>0</starttime>
            <duration>0</duration>
        </event>
    </xsl:template>

    <!--
    ####################################################################################################
    # IGNORED ELEMENTS
    # Templates below are used to explicitly ignore elements from the XMLTV input that are not mapped
    # to epgd fields to prevent "Missing definition of field" errors in the epgd log.
    ####################################################################################################
    -->
    <xsl:template match="audio"/>
    <xsl:template match="episode-num"/>
    <xsl:template match="icon"/>
    <xsl:template match="image"/>
    <xsl:template match="keyword"/>
    <xsl:template match="language"/>
    <xsl:template match="last-chance"/>
    <xsl:template match="new"/>
    <xsl:template match="orig-language"/>
    <xsl:template match="premiere"/>
    <xsl:template match="previously-shown"/>
    <xsl:template match="review"/>
    <xsl:template match="star-rating"/>
    <xsl:template match="subtitles"/>
    <xsl:template match="url"/>
    <xsl:template match="video"/>

    <!--
    ####################################################################################################
    # HELPER TEMPLATES
    # These are named templates used for common tasks like stripping HTML or mapping categories.
    ####################################################################################################
    -->

    <!-- Helper template to strip HTML tags from a string (XSLT 1.0 compatible) -->
    <xsl:template name="strip-html">
        <xsl:param name="text"/>
        <xsl:choose>
            <xsl:when test="contains($text, '&lt;') and contains($text, '&gt;')">
                <!-- Retain text before the first '<' -->
                <xsl:value-of select="substring-before($text, '&lt;')"/>
                <!-- Recursive call with the text after the first '>' -->
                <xsl:call-template name="strip-html">
                    <xsl:with-param name="text" select="substring-after($text, '&gt;')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- If no further tags are found, output the rest of the text -->
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Standard template for copying attributes -->
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>

    <!-- Named template for category mapping -->
    <xsl:template name="mapping">
        <xsl:param name="str" />
        <xsl:variable name="value_lower" select="translate($str,'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖU', 'abcdefghijklmnopqrstuvwxyzäöü')" />
        
        <xsl:variable name="temp_mapped_category_name">
            <xsl:for-each select="$category_mapping">
                <xsl:variable name="current_category_name" select="@name"/>
                <xsl:for-each select="contains">
                    <xsl:variable name="keyword_lower" select="translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖU', 'abcdefghijklmnopqrstuvwxyzäöü')" />
                    <xsl:if test="contains($value_lower, $keyword_lower)">
                        <xsl:value-of select="$current_category_name"/>
                        <xsl:text>@@STOP_PROCESSING_CATEGORY@@</xsl:text> <!-- Marker to stop further processing for this input -->
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <category>
            <xsl:choose>
                <xsl:when test="contains($temp_mapped_category_name, '@@STOP_PROCESSING_CATEGORY@@')">
                    <!-- Extract the first category name before the stop marker -->
                    <xsl:value-of select="substring-before($temp_mapped_category_name, '@@STOP_PROCESSING_CATEGORY@@')"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- No specific mapping found, default to 'Sonstige' (Other) -->
                    <xsl:text>Sonstige</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </category>
    </xsl:template>

    <!-- Reusable template to emit credit elements -->
    <xsl:template name="emit-credits">
        <xsl:param name="xpath_name"/>   <!-- The local-name of the credit element in the input XML (e.g., 'actor') -->
        <xsl:param name="element_name"/> <!-- The desired name of the output element (e.g., 'actor' or 'screenplay') -->
        <xsl:variable name="credit_nodes" select="credits/*[local-name() = $xpath_name]"/>
        <xsl:if test="$credit_nodes">
            <xsl:element name="{$element_name}">
                <xsl:for-each select="$credit_nodes">
                    <xsl:value-of select="."/>
                    <xsl:if test="@role">
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="@role"/>
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                    <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
            </xsl:element>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
