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
xquery version "3.0";
module namespace frt = "http://further.utah.edu/result-translation";

(: Import FURTHeR Module :)
(: import module namespace further = "http://further.utah.edu/xquery-functions-module"
    at "further.xq"; :)
import module namespace further = 'http://further.utah.edu/xquery-functions-module'
    at '${server.mdr.ws}${path.mdr.ws.resource.path}/fqe/further/xq/further.xq';

(: Import FURTHeR Constants Module :)
(: import module namespace const = 'http://further.utah.edu/constants' 
    at 'constants.xq'; :)
import module namespace const = 'http://further.utah.edu/constants' 
    at '${server.mdr.ws}${path.mdr.ws.resource.path}/fqe/further/xq/constants.xq';

(: ALWAYS Define Namespaces in XQUERY PROLOG! :)
declare namespace fn  = 'http://www.w3.org/2005/xpath-functions';
declare namespace fq = "http://further.utah.edu/core/query";
declare namespace dts = 'http://further.utah.edu/dts';
declare namespace mdr = "http://further.utah.edu/mdr";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare namespace xsi = "http://www.w3.org/2001/XMLSchema-instance";
declare namespace fqe = 'http://further.utah.edu/fqe'; 
(: DO NOT USE DEFAULT NAMESPACE, it may conflict with the response Namespaces :)

(: Global CONSTANTS, Always Translating FROM FURTHeR Namespace ID :)
declare variable $frt:FURTHER as xs:string := '32769';
declare variable $frt:FURTHeR as xs:string := 'FURTHeR';

(: We are using SNOMED (Namespace ID 30) for ObservationType Values :)
declare variable $frt:SNOMED as xs:string := '30';

(: DTS Terminology Namespace IDs :)
declare variable $frt:OMOP-V2 as xs:string := '32868';
declare variable $frt:ICD-9 as xs:string := '10';
declare variable $frt:LOINC as xs:string := '5102';

(: Empty String Value for Substituting Empty Arguments to Functions :)
declare variable $frt:EMPTY as xs:string := '';

(: Mark Criterias that got Skipped :)
declare variable $frt:SKIP as xs:string := 'S';

(: Yes Value Used for Translation Flag transFlag :)
declare variable $frt:YES as xs:string := 'Y';

(: No Value Used for Translation Flag transFlag :)
declare variable $frt:NO as xs:string := 'N';

(: ERROR Value Used for Translation Flag transFlag :)
declare variable $frt:ERROR as xs:string := 'E';

(: Placeholder in case preTranslation Fails :)
declare variable $frt:ZERO as xs:string := '0';

(: DELIMITER :)
declare variable $frt:DELIMITER as xs:string := '^';

(: MDR Static Property Names CASE SENSITIVE! :)
declare variable $frt:ATTR_TRANS_FUNC as xs:string := 'ATTR_TRANS_FUNC';
declare variable $frt:ATTR_VALUE_TRANS_FUNC as xs:string := 'ATTR_VALUE_TRANS_FUNC';
declare variable $frt:ATTR_VALUE_TRANS_TO_DATA_TYPE as xs:string := 'ATTR_VALUE_TRANS_TO_DATA_TYPE';
declare variable $frt:CODING_SYSTEM as xs:string := 'CODING_SYSTEM';
declare variable $frt:EXT_PERSON as xs:string := 'EXT_PERSON';

declare variable $frt:pickMe as xs:string := 'pickMe';
declare variable $frt:skipATTR as xs:string := 'skipAttr';
declare variable $frt:translateCode as xs:string := 'translateCode';
declare variable $frt:ageToBirthYear as xs:string := 'ageToBirthYear';

(: DTS Static Property Names CASE SENSITIVE! :)
declare variable $frt:CodeInSource as xs:string := 'Code in Source';
declare variable $frt:LocalCode as xs:string := 'Local Code';


(:==================================================================:)
(: Main Translate Result Function                                   :)
(:==================================================================:)
declare function frt:transResult($inputXML as document-node(),
                                 $sourceNamespaceId as xs:string,
                                 $dataSetId as xs:string)
{

  (: Get the Namespace Name Using the Namespace ID :)
  let $srcNmspcName := further:getNamespaceName($sourceNamespaceId)
  
  (: Must Keep this Order of Processing :)

  (: Call Initialization :)
  let $initialized := frt:initResultTranslation($inputXML)
  
  (: Process MDR :)
  let $processedMDR := frt:processMDR($initialized,$sourceNamespaceId)
  
  (: Process DTS :)
  let $processedDTS := frt:processDTS($processedMDR,$sourceNamespaceId)
  
  (: Process <personId> :)
  let $processedPersonId := frt:transPersonIdTags($processedDTS,$dataSetId)
  
  (: Error Handling :)
  let $validated := frt:validate($processedPersonId,$srcNmspcName)
  
  (: Call cleanup :)
  let $cleaned := frt:cleanup($validated)
  
  (: Return Final Cleaned Version :)
  return $cleaned
  
};


(:==================================================================:)
(: Initialization = Convert XML Attributes into XML Elements        :)
(:==================================================================:)
declare function frt:initResultTranslation($inputXML as document-node())
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy1 := $inputXML
modify (

  (: Since our Output Expects everything as XML Elements, and NOT XML Attributes :)
  (: We will convert all XML Attributes into XML Elements Here :)
  (: For Any Element that has any XML Attribute :)
  for $elem in $inputCopy1//*[@*]
  return replace node $elem
  with
    (: Convert the XML Attribute into an XML Element :)
    element {fn:name($elem)} {
    for $child in $elem/(@*|text())
    return element {
      if ($child instance of attribute())
      then fn:name($child)
      else 'value'} {fn:string($child)}
  }
    
) (: End Modify :)
return 
copy $inputCopy2 := $inputCopy1
modify (

  (: Insert mdrFlag for Elements :)
  for $elem in $inputCopy2/ResultList//*
    return 
	  insert node attribute mdrFlag {$frt:NO} into $elem

) (: End Modify :)
return $inputCopy2

(: END Function :)
};


(:==================================================================:)
(: Process MDR Stuff                                                :)
(:==================================================================:)
declare function frt:processMDR($inputXML as document-node(),
                             $srcNmspcId as xs:string)
{

(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: Get the Namespace Name Using the Namespace ID :)
  let $srcNmspcName := further:getNamespaceName($srcNmspcId)
  
  (: For ALL XML Element Names AND XML Attributes AFTER the ROOT Node :)
  (: Since we have converted all xml attributes into xml elements in the initResultTranslation function :)
  (: We only need to deal with Elements here :)
  (: for $field at $i in ($inputCopy/*//* , $inputCopy/*//@*) :)
  for $field at $i in $inputCopy/*//*
  
    let $fieldName := $field/name()
    let $fieldData := fn:data($field)

    (: Call MDR :)
    (: DEBUG :)
    (: let $mdrResult := concat('MDR-',$i) :)
    (: let $mdrResult := frt:getMDRAttrURL($fieldName) :)
    let $mdrResult := frt:getMDRResult($fieldName,$srcNmspcName,$frt:FURTHeR)

    return (
      
      (: DEBUG :)
      (: insert node attribute mdrURL {$mdrResult} into $field :)
      (: if there is a MDR Result :)
      if ($mdrResult/leftAsset) then (
        
        (: Rename the XML Element as the Translated Name :)
        rename node $field as $mdrResult/leftAsset/text(),
        
        (: Insert XML Attributes for Person and Person ID for later Processing :)
        if ($mdrResult/properties/entry/key = $frt:EXT_PERSON) then (
          insert node attribute rootPerson 
            {fn:substring-before($mdrResult/properties/entry/value/text(),$frt:DELIMITER)}
            into $field,
          insert node attribute personId
            {fn:substring-after($mdrResult/properties/entry/value/text(),$frt:DELIMITER)}
            into $field
        )else()
        
        , (: Set mdrFlag :)
        
        if ($mdrResult/properties/entry[key=$frt:ATTR_TRANS_FUNC and value=$frt:skipATTR]) then
          replace value of node $field/@mdrFlag with $frt:SKIP
        else
          replace value of node $field/@mdrFlag with $frt:YES
        
      )else() (: End if there is a Result :)

      , (: Do More Stuff :)

      (: For each node that does NOT have any Children AND Need DTS Translation :)
      if ($mdrResult/properties/entry/key/text() = $frt:ATTR_VALUE_TRANS_FUNC 
          and $mdrResult/properties/entry/value/text() = $frt:translateCode
          and $field[not($field//*)] ) then
          
        (: Initialize Field for DTS Translation Later :)
        insert node attribute dtsFlag {$frt:NO} into $field

      else ( (: End If Else Do Nothing :) )
      
    ) (: End Return :)

) (: End Modify :)
return $inputCopy
  
};


(:==================================================================:)
(: Process DTS Stuff                                                :)
(:==================================================================:)
declare function frt:processDTS($inputXML as document-node(),
                                $srcNmspcId as xs:string)
{

(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: Get all Fields that need DTS Translation :)
  for $field at $i in $inputCopy//*[@dtsFlag=$frt:NO]
  
    let $fieldName := $field/name()
    let $fieldData := fn:data($field)

    (: Call MDR to find out what Coding Standard to Translate to :)  
    let $term := frt:getTerminology($fieldName,$frt:FURTHeR)

    (: let $tgCodeSys := '30' :)        
    let $tgCodeSys := substring-after($term/rightAsset/text(),$frt:DELIMITER)
        
    (: Call DTS :)
    let $dtsResponse := further:getTranslatedConcept($srcNmspcId,
                                                     $frt:LocalCode,
                                                     $fieldData,
                                                     $tgCodeSys,
                                                     $frt:CodeInSource)
    (: DEBUG DTS URL :)
    (: let $dtsURL := further:getConceptTranslationRestUrl($srcNmspcId,
                                                     $frt:LocalCode,
                                                     $fieldData,
                                                     $tgCodeSys,
                                                     $frt:CodeInSource) :)

    (: DEBUG :)
    (: let $translatedPropVal := concat('DTS-',$i) :)
    let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)

    (: Replace Value of Node with Translated DTS Value :)
    return (
      replace value of node $field with $translatedPropVal,
      if ($translatedPropVal) then 
        replace value of node $field/@dtsFlag with $frt:YES
      else()
    )
  
) (: End Modify :)
return $inputCopy
  
};


(:==================================================================:)
(: Validate (Error Handling)                                        :)
(:==================================================================:)
declare function frt:validate($inputXML as document-node(),$srcNmspcName as xs:string)
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: Error out ONLY the FIRST criteria AttributeName :)
  (: This will ensure that the output xml is valid since there is no outter <errors> node at this time :)
  (: It will also prevent us from having a very long list of errors :)
  (: Within the for statement, be sure to use the parentheses after the in clause.
     Therefore, the position predicate[1] will function properly.
     if we take out the parentheses and the [1], we will list the all criterias with error.
     which we may want in the future. :)

  
  (: Check for Non-Translated Fields :)
  if ($inputCopy//*[@mdrFlag=$frt:NO]) then (

    (: Wish i could just replace, but did not work :)
    (: So I'm just deleting the whole file and then inserting the Error :)
    delete node $inputCopy/ResultList,
    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    for $field in ($inputCopy//*[@mdrFlag=$frt:NO])[1]
      let $attrName := fn:name($field)
      return
      insert node
        <error xmlns="http://further.utah.edu/core/ws">
          <code>MDR_RESULT_TRANSLATION_ERROR</code>
          <message>MDR Association for [ {$srcNmspcName}.{$attrName} ] May be Missing</message>
        </error>
        into $inputCopy 
  )
  else if ($inputCopy//*[@dtsFlag=$frt:NO]) then (
    
    (: Wish i could just replace, but did not work :)
    (: So I'm just deleting the whole file and then inserting the Error :)
    delete node $inputCopy/ResultList,
    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    for $field in ($inputCopy//*[@dtsFlag=$frt:NO])[1]
      let $attrName := fn:name($field)
      return
      insert node
        <error xmlns="http://further.utah.edu/core/ws">
          <code>DTS_RESULT_TRANSLATION_ERROR</code>
          <message>DTS Mapping for [ {$srcNmspcName}.{$attrName} ] May be Missing</message>
        </error>
        into $inputCopy 
  )
  else(
    (: Remove ALL Nodes that have been Marked to be SKIPPED :)
    delete node $inputCopy//*[@mdrFlag=$frt:SKIP]
  ) (: End IF-Else Statement :)
  
) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: Cleanup                                                          :)
(:==================================================================:)
declare function frt:cleanup($inputXML as document-node())
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (
  
  (: Delete ALL tranFlag Attributes on SUCCESS :)
  delete node $inputCopy//@rootPerson,
  delete node $inputCopy//@personId,
  delete node $inputCopy//@mdrFlag,
  delete node $inputCopy//@dtsFlag

) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: getMDRResult = ALWAYS GET ONE MDR Attribute Translation RESULT   :)
(:==================================================================:)
declare function frt:getMDRResult(
                 $srcAttrName as xs:string,
                 $srcNmspcName as xs:string,
                 $tgNmspcName as xs:string)
{ 
  (: EXAMPLE: ${server.dts.ws}/mdr/rest/asset/association/right/translatesTo/genderConceptId :)
  (:          ${server.dts.ws}/mdr/rest/asset/association/right/translatesTo/{sourceAttr} :)
  (:          http://demo.further.utah.edu:9000/mdr/rest/asset/association/right/translatesTo/genderConceptId :)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/right/translatesTo/')
  let $docUrl := fn:concat( $baseURL, $srcAttrName )
  
  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  let $doc := doc($parsedDocUrl)
  
  (: Return the AssetAssociation for the Correct Namespaces :)
  return 
    
    if (fn:count($doc//assetAssociation[rightNamespace=$srcNmspcName and leftNamespace=$tgNmspcName]) > 1) then
      $doc//assetAssociation[rightNamespace=$srcNmspcName and leftNamespace=$tgNmspcName and properties/entry/value=$frt:pickMe]
    else 
      $doc//assetAssociation[rightNamespace=$srcNmspcName and leftNamespace=$tgNmspcName]

};

(:==================================================================:)
(: getMDRAttrURL = Get URL for Debugging                            :)
(:==================================================================:)
declare function frt:getMDRAttrURL($srcAttrName as xs:string)
{ 
  (: EXAMPLE: ${server.dts.ws}/mdr/rest/asset/association/right/translatesTo/genderConceptId :)
  (:          ${server.dts.ws}/mdr/rest/asset/association/right/translatesTo/{sourceAttr} :)
  (:          http://demo.further.utah.edu:9000/mdr/rest/asset/association/right/translatesTo/genderConceptId :)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/right/translatesTo/')
  let $docUrl := fn:concat( $baseURL, $srcAttrName )

  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  return $parsedDocUrl
};


(:==================================================================:)
(: getMDRResult = ALWAYS GET ONE MDR Attribute Translation RESULT   :)
(:==================================================================:)
declare function frt:getTerminology(
                 $fieldName as xs:string,
                 $NmspcName as xs:string)
{ 
  (: EXAMPLE: ${server.dts.ws}/mdr/rest/asset/association/left/useTerminology/race :)
  (:          ${server.dts.ws}/mdr/rest/asset/association/left/useTerminology/{fieldName} :)
  (:          http://demo.further.utah.edu:9000/mdr/rest/asset/association/left/useTerminology/race :)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/left/useTerminology/')
  let $docUrl := fn:concat( $baseURL, $fieldName )
  
  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  let $doc := doc($parsedDocUrl)
  
  (: Return the AssetAssociation for the Correct Namespaces :)
  return 
    
    if (fn:count($doc//assetAssociation[leftAsset=$fieldName and leftNamespace=$NmspcName and association='useTerminology']) > 1) then
      <error>More Than One Terminology Found </error>
    else 
      $doc//assetAssociation[leftAsset=$fieldName and leftNamespace=$NmspcName and association='useTerminology']

};


(:==================================================================:)
(: printDebug = Print Debug Variable to Query Info Screen           :)
(:==================================================================:)
declare function frt:printDebug($debugVar,$msg as xs:string?)
{
  let $var := $debugVar
  return fn:trace( $var,concat('DEBUG ', $msg, '=') )
};


(:==================================================================:)
(: ageToBirthYear = Translate Age to BirthYear                      :)
(:==================================================================:)
declare function frt:ageToBirthYear($age)
{
  (: Get Current Year :)
  let $curYear := year-from-date(current-date())
  
  (: Subtract Age from CurrentYear to Get BirthYear :)
  return $curYear - $age
};


(:=====================================================================:)
(: Sanitize SINGLE & DOUBLE Quotes to Prevent XQuery Injection Attacks :)
(:=====================================================================:)
declare function frt:sanitize($inputXML as document-node()) 
as document-node()
{

(: Ideally, I want to replace all '&' characters with '&amp;'
   However, BaseX does not allow me to have this character in the xml file or output. 
   So I am skipping this for now :)

(: Transformation to replace Single Quotes with '&apos;' :)
copy $inputCopy := $inputXML
modify (
  
  for $node at $i in $inputCopy//*[contains(text(),'''')]
  return 
    replace value of node $node with replace($node, '''','&amp;apos;')
  
) (: End Modify :)

return
(: Starting another Transformation, so the replace node will not conflict :)
(: Transformation to replace Double Quotes with '&quot;' :)
copy $inputCopy2 := $inputCopy
modify (  

  for $node at $i in $inputCopy2//*[contains(text(),"""")]
  return 
    replace value of node $node with replace($node, """",'&amp;quot;')

) (: End Modify :)
return $inputCopy2

}; (: END OF FUNCTION frt:sanitize :)



(:=====================================================================:)
(: transPersonIdTags                                                   :)
(: Translate Person ID Tags                               :)
(:=====================================================================:)
declare function frt:transPersonIdTags($inputXML,$datasetId) 
{

copy $inputCopy := $inputXML
modify (
  
  (: if the MDR translated name is <personId>
     then replace it with all these tags :)   
  for $person in $inputCopy/ResultList/Person[id.id]
  
	  (: Get the Source Person Object and Person ID Attribute from MDR :)
	  let $extPersonName := $person/@rootPerson
	  (: let $srcObject := 'Person' :)
	  let $extPersonIdName := $person/@personId
	  (: let $srcPersonIdAttr := 'personId' :)
  
	  return replace node $person/id.id 
	    with frt:getPersonIdTags($extPersonName,$extPersonIdName,$person/id.id/text(),$datasetId)

) (: End Modify :)
return $inputCopy

}; (: END OF FUNCTION frt:transPersonIdTags :)


(:=====================================================================:)
(: getPersonIdTags                                                     :)
(: Construct the group of Person ID Tags                               :)
(:=====================================================================:)
declare function frt:getPersonIdTags($srcObject,$srcAttr,$srcPersonId,$datasetId) 
{
  (: Call Identity Resolution Service :)
  (: 
    REST CAll FORMAT
    
    http://demo.further.utah.edu:9000/fqe/rest/fqe/id/generate/
    {target_object}/{target_attribute}/{target_namespace}/
    {source_object}/{source_attribute}/{source_identifier}
    
    Note: 
    For Result Translation, Target is always the Central Model (FURTHER Model)
    The Source is the External Data Source Models
    
    Examples:
    http://demo.further.utah.edu:9000/fqe/rest/fqe/id/generate/PERSON/PERSON_ID/32776/PATIENT/PAT_DE_ID/12345
    http://demo.further.utah.edu:9000/fqe/rest/fqe/id/generate/PERSON/PERSON_ID/32776/PERSON/PERSON_ID/12345
  :)
  let $baseURL := fn:concat($const:fqeRestServer,'/rest/fqe/id/generate/PERSON/PERSON_ID/32776/')
  let $docUrl := fn:concat( $baseURL, $srcObject, '/' , $srcAttr , '/', $srcPersonId )
  
  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  let $result := doc($parsedDocUrl)
  
  (: Strip out the Person ID from the Result :)
  let $resolvedPersonId := $result//fqe:value/text()
  
  return(
		<personId>
		  <id>{$resolvedPersonId}</id>
		  <datasetId>{$datasetId}</datasetId>
	  </personId>
	  ,
	  <personCompositeId>{$datasetId}:{$resolvedPersonId}</personCompositeId>  
  )
  
}; (: END OF FUNCTION frt:getPersonIdTags :)


(: END OF MODULE :)
