(:
 : Copyright (C) [2013] [The FURTHeR Project]
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :         http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)

module namespace further='http://further.utah.edu/xquery-functions-module';
declare namespace dts='http://further.utah.edu/dts';
declare namespace xmi='http://schema.omg.org/spec/XMI/2.1';

(: Change the location of constants.xq when working locally :)
(: import module namespace const = 'http://further.utah.edu/constants' at 'constants.xq'; :)
import module namespace const = 'http://further.utah.edu/constants' 
    at '${server.mdr.ws}${path.mdr.ws.resource.path}/fqe/further/xq/constants.xq';

declare function further:getConceptTranslationRestUrl(
  $srcNmspc as xs:string,
  $srcPropNm as xs:string,
  $srcPropVal as xs:string, 
  $tgNmspc as xs:string, 
  $tgPropNm as xs:string)
{
  (: EXAMPLE: http://dev-esb.further.utah.edu:9000/dts/rest/translate/UUEDW/DWID/106386/SNOMED CT/Code in Source?view=HUMAN :)
  (:          http://dev-esb.further.utah.edu:9000/dts/rest/translate/{namespace}/{propertyName}/{propertyValue}/{targetNamespace}/{targetPropertyName}?view={view} :)
  let $srcPropertyVal := if (fn:string-length( $srcPropVal ) = 0) then '0' else $srcPropVal
  let $fixedSrcNamespace := further:replaceBracketsWithHexCodes( $srcNmspc )
  let $fixedTgNamespace := further:replaceBracketsWithHexCodes( $tgNmspc )
  let $docUrl := fn:concat($const:restServer, $const:dtsRestService, '/', $fixedSrcNamespace, '/', $srcPropNm, '/', $srcPropertyVal, '/', $fixedTgNamespace, '/', $tgPropNm, '?view=HUMAN')

  let $parsedDocUrl := iri-to-uri( $docUrl )
  
  return $parsedDocUrl

};

declare function further:replaceBracketsWithHexCodes( $inString as xs:string ) as xs:string* {

  let $str := replace( $inString, '\[', '%5B' )
  let $str := replace( $str, '\]', '%5D' )

  return $str
};

declare function further:getTranslatedConcept(
  $srcNmspc as xs:string,
  $srcPropNm as xs:string,
  $srcPropVal as xs:string,
  $tgNmspc as xs:string,
  $tgPropName as xs:string)
{

  let $restUrl := further:getConceptTranslationRestUrl( $srcNmspc, $srcPropNm, $srcPropVal, $tgNmspc, $tgPropName )
  return doc( $restUrl )

};

declare function further:getConceptNamespace( $concept as node()? ) as xs:string*
{
  let $nmspc := $concept/dts:concepts/dts:conceptId/namespace/text()
  return $nmspc
};

declare function further:getConceptPropertyName( $concept as node()? ) as xs:string*
{
  let $propertyName := $concept/dts:concepts/dts:conceptId/propertyName/text()
  return $propertyName
};

declare function further:getConceptPropertyValue( $concept as node()? ) as xs:string*
{
  let $propertyValue := $concept/dts:concepts/dts:conceptId/propertyValue/text()
  return $propertyValue
};

declare function further:getValueDomains()
{
  let $fmdrRestUrl := fn:concat( $const:fmdrRestServer, $const:fmdrRestService, $const:fmdrPathValueDomainsXmi)

  return doc( $fmdrRestUrl )/xmi:XMI/xmi:Extension/elements

};

declare function further:getValueDomainPropertyValue( $valueDomains as node(), $valueDomainName as xs:string, $propertyName as xs:string ) 
{
  let $val := string($valueDomains/element[@name=$valueDomainName]/tags/tag[@name=$propertyName]/@value)
  return $val
};

declare function further:getValueDomainNamespaceName( $valueDomains as node(), $valueDomainName as xs:string )
{
  let $nmspc := further:getValueDomainPropertyValue( $valueDomains, $valueDomainName,'DTSNamespace') 
  return $nmspc

};

declare function further:getValueDomainPropertyName( $valueDomains as node(), $valueDomainName as xs:string )
{
  let $propertyName := further:getValueDomainPropertyValue( $valueDomains, $valueDomainName,'DTSPropertyName') 
  return $propertyName

};

declare function further:getValueDomainPropertyValue( $valueDomains as node(), $valueDomainName as xs:string )
{
  let $propertyValue :=  further:getValueDomainPropertyValue( $valueDomains, $valueDomainName,'DTSPropertyValue')
  return $propertyValue

};

(:==================================================================:)
(: Return DTS namespace name by namespace ID                        :)
(:==================================================================:)
declare function further:getNamespaceName(
  $namespaceId as xs:string)
{
  (: Form the DTS web service request URL :)
  (: EXAMPLE: http://dev-esb.further.utah.edu:9000/dts/rest/search/ns/32779 :)
  let $docUrl := fn:concat($const:restServer, $const:dtsSearchService, '/ns/', $namespaceId)

  (: Get the DTS web service response :)
  let $parsedDocUrl := iri-to-uri( $docUrl )

  (: Find the namespace name in the XML response document :) 
  return doc( $parsedDocUrl )/dts:namespace/name/text()  
};
