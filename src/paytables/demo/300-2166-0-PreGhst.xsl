<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var imageOrder = getOutcomeData(scenario, 0);
						var mainData = getOutcomeData(scenario, 1);
						var coinData = getOutcomeData(scenario, 2);
						var wheelData = getOutcomeData(scenario, 3);
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');

						// Output Image Assignment table.
						const prizeList = 'ABCDEFGHIJK';
						var r = [];

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
 						r.push('<tr>');
						r.push('<td class="tablehead" colspan="' + imageOrder.length + '">');
 						r.push(getTranslationByName("imageAssignment", translations));
 						r.push('</td>');
						r.push('</tr>');

 						r.push('<tr>');

 						for (var imageIndex = 0; imageIndex < imageOrder.length; imageIndex++)
 						{
 							r.push('<td class="tablebody" style="padding-right:10px">');
 							r.push(getTranslationByName("imageBank" + PrizeImage(prizeList[imageIndex],imageOrder), translations));
 							r.push('</td>');
 						}

 						r.push('</tr>');
						r.push('<tr>');

 						for (var imageIndex = 0; imageIndex < imageOrder.length; imageIndex++)
 						{
 							r.push('<td class="tablebody" style="padding-right:10px">');
 							r.push(convertedPrizeValues[imageIndex]);
 							r.push('</td>');
 						}
						 
 						r.push('</tr>');
						r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
 						r.push('</table>');

						// Output Main Game table.
						var mainPrizeCounts = [];
						var mainMatchCount = [];
						var gameSymb = '';
						var symbIndex = 0;
						var isMatch3 = false;
						var imageText = '';
						var matchText = '';
						var prizeText = '';

 						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr>');
						r.push('<td class="tablehead" colspan="3">');
 						r.push(getTranslationByName("mainGame", translations));
 						r.push('</td>');
						r.push('</tr>');
						r.push('<tr>');
						r.push('<td class="tablehead" style="padding-right:10px">' + getTranslationByName("turn", translations) + '</td>');
						r.push('<td class="tablehead" style="padding-right:10px">' + getTranslationByName("image", translations) + '</td>');
						r.push('<td class="tablehead" style="padding-right:10px">' + getTranslationByName("prizeValue", translations) + '</td>');
						r.push('</tr>');

						mainPrizeCounts = [0,0,0,0,0,0,0,0,0,0,0];
						mainMatchCount = [0,0,0,0,0,0,0,0,0,0,0];

						for (var turnIndex = 0; turnIndex < mainData.length; turnIndex++)
						{
							gameSymb = mainData[turnIndex];
							mainPrizeCounts[prizeList.indexOf(gameSymb[0])]++;
						}

						for (var turnIndex = 0; turnIndex < mainData.length; turnIndex++)
						{
							gameSymb = mainData[turnIndex];
							symbIndex = prizeList.indexOf(gameSymb);

							if (symbIndex != -1)
							{
								isMatch3 = (mainPrizeCounts[symbIndex] == 3);
								matchText = (isMatch3) ? ' : ' + getTranslationByName("match3", translations) : '';
								mainMatchCount[symbIndex] += (isMatch3) ? 1 : 0;
								prizeText = (mainMatchCount[symbIndex] == 3) ? convertedPrizeValues[getPrizeNameIndex(prizeNames,gameSymb)] : '';
								imageText = getTranslationByName("imageBank" + PrizeImage(gameSymb,imageOrder), translations);
							}
							else
							{
								matchText = '';
								prizeText = '';

								if (gameSymb == 'X')
								{
									imageText = getTranslationByName("coinBonusGame", translations);
								}
								else if (gameSymb == 'Y')
								{
									imageText = getTranslationByName("wheelBonusGame", translations);
								}
							}

							r.push('<tr>');
							r.push('<td class="tablebody" style="padding-right:10px">' + (turnIndex+1).toString() + '</td>');
							r.push('<td class="tablebody" style="padding-right:10px">' + imageText + matchText + '</td>');
							r.push('<td class="tablebody" style="padding-right:10px">' + prizeText + '</td>');
							r.push('</tr>');
						}

						r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
						r.push('</table>');

						// Output Coin Bonus Game table.
						if (coinData.length != 0)
						{
							var coinIndex = 0;

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr>');
							r.push('<td class="tablehead" colspan="1">');
							r.push(getTranslationByName("coinBonusGame", translations));
							r.push('</td>');
							r.push('</tr>');
							r.push('<tr>');
							r.push('<td class="tablehead">' + getTranslationByName("wins", translations) + '</td>');
							r.push('</tr>');

							while (coinData[coinIndex] != 'Z')
							{
								gameSymb = coinData[coinIndex];

								r.push('<tr>');
								r.push('<td class="tablebody">' + convertedPrizeValues[getPrizeNameIndex(prizeNames,gameSymb)] + '</td>');
								r.push('</tr>');

								coinIndex++;
							}

							r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
							r.push('</table>');
						}

						//Output Wheel Bonus Game table
						if (wheelData.length != 0)
						{
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr>');
							r.push('<td class="tablehead" colspan="1">');
							r.push(getTranslationByName("wheelBonusGame", translations));
							r.push('</td>');
							r.push('</tr>');
							r.push('<tr>');
							r.push('<td class="tablehead">' + getTranslationByName("wins", translations) + '</td>');
							r.push('</tr>');
							r.push('<tr>');
							r.push('<td class="tablebody">' + convertedPrizeValues[prizeNames.indexOf(wheelData)] + '</td>');
							r.push('</tr>');
							r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
							r.push('</table>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
						r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");


						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "ACJFHKBEDIG|KCDIGYAFJEHBXJGI|VSWRWUZ|W11"
					// Output: ["A", "C", "J", "F", ...] or ["K", "C", "D", "I", ...] or ["V", "S", "W", ...] or "W11"
					function getOutcomeData(scenario, index)
					{
						var outcomeData = scenario.split("|");

						if (index >= 0 && index <= 2)
						{
							return outcomeData[index].split("");
						}
						else if (index == 3)
						{
							return outcomeData[index];
						}
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					// Input: one of the prizes in "A" to "K", and array of re-Ordered images
					// Output: string of index of image in Image Bank
					function PrizeImage(imageChar,imageOrder)
					{
						var imageIndex = imageOrder.indexOf(imageChar);
						return (imageIndex+1).toString();
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								//registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
