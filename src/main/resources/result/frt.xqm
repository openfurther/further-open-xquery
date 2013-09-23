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
declare variable $frt:EXT_ROOT_ID_ATTR as xs:string := 'EXT_ROOT_ID_ATTR';

declare variable $frt:pickMe as xs:string := 'pickMe';
declare variable $frt:skipATTR as xs:string := 'skipAttr';
declare variable $frt:translateCode as xs:string := 'translateCode';
declare variable $frt:ageToBirthYear as xs:string := 'ageToBirthYear';

(: DTS Static Property Names CASE SENSITIVE! :)
declare variable $frt:CodeInSource as xs:string := 'Code in Source';
declare variable $frt:LocalCode as xs:string := 'Local Code';


(:==================================================================:)
(: Main Translate Result Function                                   :)
(: Our Goal here is to construct the Target Central Model           :)
(:==================================================================:)
declare function frt:transResult($inputXML as document-node(),
                                 $extNmspcId as xs:string,
                                 $dataSetId as xs:string)
{

  (: Get the Namespace Name Using the Namespace ID :)
  let $extNmspcName := further:getNamespaceName($extNmspcId)
  
  (: Must Keep this Order of Processing :)

  (: Create Empty Person Template :)
  let $emptyPerson := frt:createPersonTemplate($extNmspcName)

  (: Initialize Empty Person Template with MDR Properties :)
  let $mdrPerson := frt:initPersonTemplate($emptyPerson,$extNmspcName)
  
  return
    
    (: Validate Initialized Template :)
    if ($mdrPerson/*[@extRootObject=$frt:ERROR]) then

		  (: Error Handling :)
		  frt:validateTemplate($mdrPerson,$extNmspcName)
      
    else (: Continue Processing :)
    
		  (: Read the Input File from External Result for Processing :)
      (: Returns a document node for the following functions :)
		  let $transResult := frt:process($mdrPerson,$inputXML,$extNmspcId,$dataSetId)

		  (: Error Handling :)
		  let $validated := frt:validate($transResult,$extNmspcName)
      
		  (: Call cleanup Transformation :)
		  let $cleaned := frt:cleanup($validated)

		  (: Return Final Cleaned Version :)
		  return $cleaned

};


(:==================================================================:)
(: createPersonTemplate = Create Person Template XML Format         :)
(:==================================================================:)
declare function frt:createPersonTemplate($extNmspcName as xs:string)
as document-node()
{

(: Create a Document Type Here! :)
document
{
  <Person centralRootObject="{$frt:EMPTY}" extRootObject="{$frt:EMPTY}">
    <id></id>
    <administrativeGenderNamespaceId>{$frt:SNOMED}</administrativeGenderNamespaceId>
    <administrativeGender extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></administrativeGender>
    <raceNamespaceId>{$frt:SNOMED}</raceNamespaceId>
    <race extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></race>
    <ethnicityNamespaceId>{$frt:SNOMED}</ethnicityNamespaceId>
    <ethnicity extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></ethnicity>
    <dateOfBirth extPath="{$frt:EMPTY}"></dateOfBirth>
    <birthYear extPath="{$frt:EMPTY}"></birthYear>
    <birthMonth extPath="{$frt:EMPTY}"></birthMonth>
    <birthDay extPath="{$frt:EMPTY}"></birthDay>
    <educationLevel extPath="{$frt:EMPTY}"></educationLevel>
    <primaryLanguageNamespaceId>{$frt:SNOMED}</primaryLanguageNamespaceId>
    <primaryLanguage extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></primaryLanguage>
    <maritalStatusNamespaceId>{$frt:SNOMED}</maritalStatusNamespaceId>
    <maritalStatus extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></maritalStatus>
    <religionNamespaceId>{$frt:SNOMED}</religionNamespaceId>
    <religion extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></religion>
    <multipleBirthIndicator extPath="{$frt:EMPTY}"></multipleBirthIndicator>
    <multipleBirthIndicatorOrderNumber extPath="{$frt:EMPTY}"></multipleBirthIndicatorOrderNumber>
    <causeOfDeathNamespaceId>{$frt:SNOMED}</causeOfDeathNamespaceId>
    <causeOfDeath extPath="{$frt:EMPTY}" dtsTerm="{$frt:SNOMED}" dtsFlag="{$frt:EMPTY}"></causeOfDeath>
    <dateOfDeath extPath="{$frt:EMPTY}"></dateOfDeath>
    <deathYear extPath="{$frt:EMPTY}"></deathYear>
    <pedigreeQuality extPath="{$frt:EMPTY}"></pedigreeQuality>
  </Person>
}

(: END Function :)
};


(:==================================================================:)
(: initPersonTemplate = Create Person Template XML Format           :)
(:==================================================================:)
declare function frt:initPersonTemplate($emptyPerson as document-node(),
                                        $extNmspcName as xs:string)
as document-node()
{
  
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $emptyPerson
modify (
  
  (: Find the Central Root Object :)
  (: The Name of the Root Element is the Name of the Central Root Object :)
  let $centralRootObject := fn:name($inputCopy/child::node())
  return (
    
    (: Set the Central Root Object XML Attribute :)
    replace value of node $inputCopy//@centralRootObject with $centralRootObject

    , (: DO MORE STUFF :)

    (: Find the External Root Object to Use as a Reference Point for External XML Doc :)
    let $extRootObject := frt:getExtRootObject($centralRootObject,$extNmspcName)
    return
      replace value of node $inputCopy//@extRootObject with $extRootObject

    , (: DO MORE STUFF :)
    
    (: Populate the extPath XML Attributes in the Template from MDR :)
    for $centralAttr in $inputCopy//*[@extPath=$frt:EMPTY]
      let $extPath := frt:getExtPath(name($centralAttr),$frt:FURTHeR,$extNmspcName)
      return replace value of node $centralAttr/@extPath with $extPath
      
    , (: DO MORE STUFF :)
    
    (: Set DTS Translation Instruction from MDR :)
    for $dtsAttr in $inputCopy//*[@dtsFlag]
      let $dtsFlag := frt:getDTSFlag(name($dtsAttr),$frt:FURTHeR,$extNmspcName)
      return replace value of node $dtsAttr/@dtsFlag with $dtsFlag
   
  ) (: End Return :)
  
) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: validateTemplate (Error Handling)                                :)
(:==================================================================:)
declare function frt:validateTemplate($inputXML,$srcNmspcName as xs:string)
as document-node()
{

(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  if ($inputCopy/*[@extRootObject=$frt:ERROR]) then 

    (: Get Name of the XML Root Node (Central Root Object) :)
    let $attrName := fn:name($inputCopy/*[@extRootObject=$frt:ERROR])
    return
    (: replace ONLY Works when we are Referring to a Document Type (NOT Element Type) :)
    replace node $inputCopy/*
       with 
       <error xmlns="http://further.utah.edu/core/ws">
         <code>MDR_RESULT_TRANSLATION_ERROR</code>
         <message>MDR Association for [ {$srcNmspcName}.{$attrName} ] May be Missing</message>
       </error>
  
  else ()
  
) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: process = Processing Function                                    :)
(:==================================================================:)
declare function frt:process($mdrPerson,$extXML,$extNmspcId,$dataSetId)
{
  
  (: Get the Namespace Name Using the Namespace ID :)
  let $extNmspcName := further:getNamespaceName($extNmspcId)
  
  (: High Level WorkFlow
	  1) Find the rootObject in the External Model by using the extRootObject Attribute Hint
	  2) For each rootObject in the External Model, create a mdrPerson Node and populate it with DTS Translated Data
	  3) Replace the <id> node with getPersonId function
	  4) Place the full result in a <ResultList> node
  :)
  
  (: Get External Root Object :)
  let $extRootObject := fn:substring-before($mdrPerson//@extRootObject,$frt:DELIMITER)
  
  (: Loop to Return ALL External Root Objects :)
  return 
  
  if ($extXML[ResultList]) then 
	  document{
		  <ResultList>
		    {
		      for $extRoot at $i in $extXML/ResultList/*[fn:name()=$extRootObject]
		      (: debug
		         return $extRootObject :)
		      return frt:transPerson($mdrPerson,$extRoot,$extNmspcId,$dataSetId)
		    }
		  </ResultList>
	  }
  else
    document {
      <error xmlns="http://further.utah.edu/core/ws">
        <code>INVALID_RESULTLIST_ERROR</code>
        <message>Invalid ResultList for Namespace [ {$extNmspcName} ] </message>
      </error>
    }
    
(: END Function :)
};


(:==================================================================:)
(: transPerson = Translate Single Person                            :)
(:==================================================================:)
declare function frt:transPerson($mdrPerson,$extPerson,$extNmspcId,$dataSetId)
as document-node()
{

(: 
1) Get Data from External Input File and Populate our Template
2) Get DTS Translated Data if necessary
3) Replace the <id> node with getPersonId function
:)
  
(: BEGIN XQUERY TRANSFORMATION :)
copy $transFields := $mdrPerson
modify (

  (: Get Data from External Person :)  
  for $field in $transFields//*[@extPath != $frt:EMPTY]
    (: Get the External Field Value using Dynamic Evaluation Function :)
    (: Full Path should be starting from under the rootObject node :)
    (: Create a String to represent the Full Document Path :)
    let $s := concat("$doc",$field/@extPath)
    (: Evaluate the String with a mapping to the document/element :)
    (: Took long time to figure this out, it is amazing when it works! :)
    let $extValue := xquery:eval($s,map {"doc" := $extPerson})
    let $cnt := fn:count($extValue)
    return (
	    if ( $cnt > 1 ) then
		    insert node attribute multiError {$cnt} into $field
	      else
        replace value of node $field with $extValue
    )

) (: End Modify :)
return 

(: BEGIN XQUERY TRANSFORMATION :)
copy $transDTS := $transFields
modify (

  (: Get Data from External Person :)  
  for $field in $transDTS//*[@dtsFlag=$frt:translateCode]

    let $dtsSrcPropVal := $field/text()
    let $tgTerm := $field/@dtsTerm
    
    (: Call DTS :)
    let $dtsResponse := further:getTranslatedConcept($extNmspcId,
                                                     $frt:LocalCode,
                                                     $dtsSrcPropVal,
                                                     $tgTerm,
                                                     $frt:CodeInSource)
    (: DEBUG DTS URL :)
    (: let $dtsURL := further:getConceptTranslationRestUrl($extNmspcId,
                                                        $frt:LocalCode,
                                                        $dtsSrcPropVal,
                                                        $tgTerm,
                                                        $frt:CodeInSource) :)

    (: Get Translated Value :)
    let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)
     
    return
      if ($translatedPropVal) then (
        replace value of node $field with $translatedPropVal
        ,
        replace value of node $field/@dtsFlag with $frt:YES
      )
      else 
        (: Always return Error if there is no DTS Mapping :)
        replace value of node $field/@dtsFlag with $frt:ERROR

) (: End Modify :)
return 

(: BEGIN XQUERY TRANSFORMATION :)
copy $transRootId := $transDTS
modify (

  (: Find the External Root Object & Root Object Attr :)
  let $extRootObject := fn:substring-before($transRootId//@extRootObject,$frt:DELIMITER)
  let $extRootObjectAttr := fn:substring-after($transRootId//@extRootObject,$frt:DELIMITER)
  return 
    replace node $transRootId//id 
       with frt:getPersonId($extNmspcId,$extPerson,$extRootObject,$extRootObjectAttr,$dataSetId)

) (: End Modify :)
return $transRootId


(: END Function :)
};


(:==================================================================:)
(: Validate (Error Handling)                                        :)
(:==================================================================:)
declare function frt:validate($inputXML as document-node(),$srcNmspcName as xs:string)
as document-node()
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
  
  if ($inputCopy/ResultList//*[@dtsFlag=$frt:ERROR]) then (

    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    for $field in ($inputCopy/ResultList//*[@dtsFlag=$frt:ERROR])[1]
    let $attrName := fn:name($field)
      return
      replace node $inputCopy/*
         with
         <error xmlns="http://further.utah.edu/core/ws">
           <code>DTS_RESULT_TRANSLATION_ERROR</code>
           <message>DTS Mapping for [ {$srcNmspcName}.{$attrName} ] May be Missing</message>
         </error>
  )
  else(
    (: Remove ALL Nodes that have been Marked to be SKIPPED :)
    delete node $inputCopy/ResultList//*[@extPath=$frt:SKIP]
  ) (: End IF-Else Statement :)
  
) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: Cleanup                                                          :)
(:==================================================================:)
declare function frt:cleanup($inputXML)
{

(: BEGIN XQUERY TRANSFORMATION :)
copy $inputCopy1 := $inputXML
modify (
  
  (: Remove ALL Empty Data Nodes :)
  for $node in $inputCopy1/ResultList//*[@extPath=$frt:EMPTY]
    return delete node $node
        
  , (: Delete ALL tranFlag Attributes on SUCCESS :)
  delete node $inputCopy1/ResultList//@extRootObject,
  delete node $inputCopy1/ResultList//@centralRootObject,
  delete node $inputCopy1/ResultList//@extPath,
  delete node $inputCopy1/ResultList//@dtsTerm,
  delete node $inputCopy1/ResultList//@dtsFlag
  
) (: End Modify :)
return

(: BEGIN XQUERY TRANSFORMATION :)
copy $inputCopy2 := $inputCopy1
modify (
  
  (: Remove ALL Empty Namespace Nodes :)
	(: Loop through Each Person rootObject :)
	for $person in $inputCopy2/ResultList/Person
	
	  (: For ALL Namespace Nodes :)
	  for $nmspcNode in $person//*[fn:contains(fn:name(),'NamespaceId')]
	    
	    (: Get the coresponding data node name :)
	    let $dataNodeName := fn:substring-before(fn:name($nmspcNode),'NamespaceId')
	    
	    return (:insert node attribute debug {$dataNodeName} into $nmspcNode:)
	      (: Remove ALL Namespace Nodes if coresponding dataNode does NOT exist :)
        if (fn:not(fn:exists($person//*[fn:name()=$dataNodeName]))) then
	        delete node $nmspcNode
	      else()
  
) (: End Modify :)
return $inputCopy2

(: END Function :)
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
(: getPersonId = Construct the group of Person ID Tags                 :)
(:=====================================================================:)
declare function frt:getPersonId($extNmspcId,$extPerson,$extRootObject,$extRootObjectAttr,$dataSetId) 
{
  (: Get the External ID Value :)
  let $s := concat("$doc/",$extRootObjectAttr)
      
  (: Evaluate the String with a mapping to the document/element :)
  (: Took long time to figure this out, it is amazing when it works! :)
  let $extIdValue := xquery:eval($s,map {"doc" := $extPerson})

  let $cnt := fn:count($extIdValue)
  return (
	  if ( $cnt > 1 ) then 
      <id multiError='{$cnt}'/>
	  else 
		  (: Call Identity Resolution Service :)
		  (: 
		    REST CAll FORMAT
		    
		    http://demo.further.utah.edu:9000/fqe/mpi/rest/id/generate/
		    {target_object}/{target_attribute}/{source_namespace_id}/
		    {source_object}/{source_attribute}/{source_id_value}/{queryId}
		    
		    Note: 
		    For Result Translation, Target is always the Central Model (FURTHER Model)
		    The Source is the External Data Source Models
		    
		    Examples:
http://demo.further.utah.edu:9000/fqe/mpi/rest/id/generate/PERSON/FPERSON_ID/32868/PERSON/PERSONID/12345/862c9130-0e89-11e3-bb9f-f23c91aec05e
http://demo.further.utah.edu:9000/fqe/mpi/rest/id/generate/PERSON/FPERSON_ID/32776/PATIENT/PAT_DE_ID/12345/862c9130-0e89-11e3-bb9f-f23c91aec05e
		  :)
      
      (: Built the REST URL :)     
		  let $baseURL := fn:concat($const:fqeRestServer,'/mpi/rest/id/generate/PERSON/FPERSON_ID/')
		  let $docUrl := fn:concat($baseURL, $extNmspcId, '/', $extRootObject, '/' , $extRootObjectAttr , '/', $extIdValue , '/', $dataSetId)
		  
		  (: Prevent XQuery Injection Attacks :)
		  let $parsedDocUrl := iri-to-uri($docUrl)
		  let $result := doc($parsedDocUrl)
		  
		  (: Strip out the Person ID from the Result :)
		  (: let $resolvedPersonId := $result//fqe:value/text() :)
		  let $resolvedPersonId := $result/fqe:id/fqe:value/text()

		  return (
        
        (: DEBUG with trace :)
        (: trace($resolvedPersonId, 'ResolvedPersonID'), :)

				<id>
				  <datasetId>{$dataSetId}</datasetId>
		      <id>{$resolvedPersonId}</id>
			  </id>
			  ,
			  <compositeId>{$dataSetId}:{$resolvedPersonId}</compositeId>  
		  )
      
  ) (: End of Return :)
    
}; (: END OF FUNCTION :)


(:==================================================================:)
(: getLeftAssoc = Get Left Assocation from MDR                      :)
(:==================================================================:)
declare function frt:getLeftAssoc(
                 $leftAttrName as xs:string,
                 $leftNmspcName as xs:string,
                 $rightNmspcName as xs:string)
{ 
  (: EXAMPLE: ${server.dts.ws}/mdr/rest/asset/association/left/translatesTo/genderConceptId :)
  (:          ${server.dts.ws}/mdr/rest/asset/association/left/translatesTo/{sourceAttr} :)
  (:          http://demo.further.utah.edu:9000/mdr/rest/asset/association/left/translatesTo/administrativeGender :)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/left/translatesTo/')
  let $docUrl := fn:concat( $baseURL, $leftAttrName )
  
  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  let $doc := doc($parsedDocUrl)
  
  (: Return the AssetAssociation for the Correct Namespaces :)
  return 
    
    if (fn:count($doc//assetAssociation[rightNamespace=$rightNmspcName and leftNamespace=$leftNmspcName]) > 1) then
      $doc//assetAssociation[rightNamespace=$rightNmspcName and leftNamespace=$leftNmspcName and properties/entry/value=$frt:pickMe]
    else 
      $doc//assetAssociation[rightNamespace=$rightNmspcName and leftNamespace=$leftNmspcName]

};


(:==================================================================:)
(: getExtPath = GET XPath of XML Element in External XML from MDR   :)
(:==================================================================:)
declare function frt:getExtPath(
                 $leftAttrName as xs:string,
                 $leftNmspcName as xs:string,
                 $rightNmspcName as xs:string)
{ 
  let $leftAssoc := frt:getLeftAssoc($leftAttrName,$leftNmspcName,$rightNmspcName)

  (: Extract Out the External XPath Value :)
  for $entry in $leftAssoc/properties/entry[key='RESULT_PATH']
  return 
    if ($entry) then $entry/value
    else $frt:EMPTY

};


(:==================================================================:)
(: getDTSFlag = GET DTS Instruction for External XML from MDR       :)
(:==================================================================:)
declare function frt:getDTSFlag(
                 $leftAttrName as xs:string,
                 $leftNmspcName as xs:string,
                 $rightNmspcName as xs:string)
{ 
  let $leftAssoc := frt:getLeftAssoc($leftAttrName,$leftNmspcName,$rightNmspcName)

  (: Extract Out the External XPath Value :)
  for $entry in $leftAssoc/properties/entry[key=$frt:ATTR_VALUE_TRANS_FUNC]
  return 
    if ($entry) then $entry/value
    else $frt:EMPTY

};


(:==================================================================:)
(: getExtRootObject = GET External rootObject from MDR              :)
(:==================================================================:)
declare function frt:getExtRootObject(
                 $centralRootObject as xs:string,
                 $extNmspcName as xs:string
                 )
{

  let $leftAssoc := frt:getLeftAssoc($centralRootObject,$frt:FURTHeR,$extNmspcName)
  
  return
  
    (: if there is an Association Result :)
    if ($leftAssoc/properties/entry[key=$frt:EXT_ROOT_ID_ATTR]) then
  
      (: Get the External Root Object:)  
      let $extRootObject := $leftAssoc/rightAsset/text()
  
      (: Get the External Root Object ID Attribute :)
      let $extRootObjectAttr :=
        for $entry in $leftAssoc/properties/entry[key=$frt:EXT_ROOT_ID_ATTR]
          return $entry/value/text()
  
      (: Return Concatenated String :)
      return concat($extRootObject,$frt:DELIMITER,$extRootObjectAttr)
    
    else $frt:ERROR

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


(: END OF MODULE :)
