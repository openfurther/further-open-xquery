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
 
(: The Calling Program for this Module is fqtCall.xq :)
xquery version "3.0";
module namespace fqt = "http://further.utah.edu/query-translation";

(: Import FURTHeR Module :)
(: Change the location of further.xq when working locally :)
(: import module namespace further = "http://further.utah.edu/xquery-functions-module"
    at "../common/further.xq"; :)
import module namespace further = 'http://further.utah.edu/xquery-functions-module'
       at '${server.mdr.ws}${path.mdr.ws.resource.path}/fqe/further/xq/further.xq';

(: Import FURTHeR Constants Module :)
(: Change the location of constants.xq when working locally :)
(: import module namespace const = 'http://further.utah.edu/constants' 
    at '../common/constants.xq'; :)
import module namespace const = 'http://further.utah.edu/constants' 
       at '${server.mdr.ws}${path.mdr.ws.resource.path}/fqe/further/xq/constants.xq';

(: Optional Functx Module :)
(: import module namespace functx = 'http://www.functx.com' 
    at 'functx.xqm'; :)

(: ALWAYS Define Namespaces in XQUERY PROLOG! :)
declare namespace fn  = 'http://www.w3.org/2005/xpath-functions';
declare namespace fq = "http://further.utah.edu/core/query";
declare namespace dts = 'http://further.utah.edu/dts';
declare namespace mdr = "http://further.utah.edu/mdr";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare namespace xsi = "http://www.w3.org/2001/XMLSchema-instance";
(: DO NOT USE DEFAULT NAMESPACE, it may conflict with the response Namespaces :)

(: Global CONSTANTS, Always Translating FROM FURTHeR Namespace ID :)
declare variable $fqt:FURTHeR := 'FURTHER';
declare variable $fqt:FURTHER as xs:string := '32769';
(: We are using SNOMED (Namespace ID 30) for ObservationType Values :)
declare variable $fqt:SNOMED as xs:string := '30';

(: OMOP has a special case where ICD-9 needs to be translated to SNOMED first, 
   before translating to OMOP-V2 
   SNOMED uses the Standard 'Code in Source' Property Name :)
declare variable $fqt:OMOP-V2 as xs:string := '32868';
declare variable $fqt:ICD-9 as xs:string := '10';
declare variable $fqt:LOINC as xs:string := '5102';

(: Empty String Value for Substituting Empty Arguments to Functions :)
declare variable $fqt:EMPTY as xs:string := '';

(: Mark Criterias that got Skipped :)
declare variable $fqt:SKIP as xs:string := 'S';

(: Yes Value Used for Translation Flag transFlag :)
declare variable $fqt:YES as xs:string := 'Y';

(: No Value Used for Translation Flag transFlag :)
declare variable $fqt:NO as xs:string := 'N';

(: ERROR Value Used for Translation Flag transFlag :)
declare variable $fqt:ERROR as xs:string := 'E';

(: Placeholder in case preTranslation Fails :)
declare variable $fqt:ZERO as xs:string := '0';

(: General Delimiter :)
declare variable $fqt:DELIMITER as xs:string := '^';
declare variable $fqt:STATIC as xs:string := 'STATIC';

(: MDR Static Property Names CASE SENSITIVE! :)
declare variable $fqt:ATTR_TRANS_FUNC as xs:string := 'ATTR_TRANS_FUNC';
declare variable $fqt:ATTR_VALUE_TRANS_FUNC as xs:string := 'ATTR_VALUE_TRANS_FUNC';
declare variable $fqt:ATTR_VALUE_TRANS_TO_DATA_TYPE as xs:string := 'ATTR_VALUE_TRANS_TO_DATA_TYPE';
declare variable $fqt:MORE_CRITERIA as xs:string := 'MORE_CRITERIA';
declare variable $fqt:ATTR_ALIAS as xs:string := 'ATTR_ALIAS';
declare variable $fqt:EXTRA_ALIAS as xs:string := 'EXTRA_ALIAS';

declare variable $fqt:skipATTR as xs:string := 'skipAttr';
declare variable $fqt:translateCode as xs:string := 'translateCode';
declare variable $fqt:ageToBirthYear as xs:string := 'ageToBirthYear';
declare variable $fqt:devNull as xs:string := 'devNull';
declare variable $fqt:ReplaceMe as xs:string := 'ReplaceMe';

(: DTS Static Property Names CASE SENSITIVE! :)
declare variable $fqt:dtsSrcPropNm as xs:string := 'Code in Source';
declare variable $fqt:dtsTgPropName as xs:string := 'Local Code';

(: Criteria searchType :)
declare variable $fqt:SIMPLE as xs:string := 'SIMPLE';
declare variable $fqt:BETWEEN as xs:string := 'BETWEEN';
declare variable $fqt:LIKE as xs:string := 'LIKE';
declare variable $fqt:IN as xs:string := 'IN';

(:==================================================================:)
(: Main Translate Query Function                                    :)
(:==================================================================:)
declare function fqt:transQuery($inputXML as document-node(),$targetNamespaceId as xs:string)
{
  (: Get the Namespace Name Using the Namespace ID :)
  let $tgNmspcName := further:getNamespaceName($targetNamespaceId)
  
  (: Must Keep this Order of Processing :)
  
  (: Call Initialization :)
  let $initializedInput := fqt:initQueryTranslation($inputXML)
  
  (: Call insertObsType :)
  let $obsTypeInput := fqt:insertObsType($initializedInput)
  
  (: Call preTransOMOP Special Case :)
  (: Possibly make preTranslations Generic (MDR Driven) to ALL Data Sources in the Future :)
  let $preTranslatedOMOP := fqt:preTransOMOP($obsTypeInput,$targetNamespaceId)
  
  (: Call transCriteriaPhrase :)
  let $translatedCriteriaPhrase := fqt:transCriteriaPhrase($preTranslatedOMOP,$targetNamespaceId)
    
  (: Call transSingleCriteria :)
  let $translatedSingleCriteria := fqt:transSingleCriteria($translatedCriteriaPhrase,$targetNamespaceId)

  (: Call transAlias :)
  let $translatedAlias := fqt:transAlias($translatedSingleCriteria,$targetNamespaceId)

  let $updatedParmAlias := fqt:updateParmAlias($translatedAlias)
  
  (: Call transRoot :)
  let $translatedRoot := fqt:transRoot($updatedParmAlias,$targetNamespaceId)
  
  (: Call dedupAliases :)
  let $dedupedAliases := fqt:dedupAliases($translatedRoot)
  
  (: Call transMoreCriteria AFTER Translations are Completed Above! :)
  let $translatedMoreCriteria := fqt:transMoreCriteria($dedupedAliases)
  
  (: Call validate for Errors :)
  let $validated := fqt:validate($translatedMoreCriteria,$tgNmspcName)
  
  (: Call cleanup :)
  let $cleaned := fqt:cleanup($validated)
  
  (: Return Final Cleaned Version :)
  (: return $debug :)
  return $cleaned
  
};


(:==================================================================:)
(: Initialization = Mark All Criterias as NOT Translated            :)
(:==================================================================:)
declare function fqt:initQueryTranslation($inputXML as document-node())
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy1 := $inputXML
modify (

  (: For rootCriterion nodes that needs to be Translated 
     Insert Attribute and Rename them as a <criteria> node 
     The rename has to be done in a separate transformation,
     since we cannot change the same node in one xquery transformation :)
  for $rootCriterion in $inputCopy1//fq:rootCriterion[fq:parameters]
    return insert node attribute rootCriterion {$fqt:YES} into $rootCriterion

) (: End Modify :)
return 
copy $inputCopy2 := $inputCopy1
modify (

  (: Rename <rootCriterion> to <criteria> if it needs processing :)
  for $rootCriterion in $inputCopy2//fq:rootCriterion[fq:parameters]
    return
      rename node $rootCriterion as QName("http://further.utah.edu/core/query", "criteria")

) (: End Modify :)
return 
copy $inputCopy3 := $inputCopy2
modify (

  (: Insert Flags for each Criteria that needs Tranlation :)
  for $criteria in $inputCopy3//fq:criteria[fq:parameters]
    return (
      insert node attribute transFlag {$fqt:NO} into $criteria,
      insert node attribute mdrFlag {$fqt:NO} into $criteria
    )
  ,
  (: dtsFlag needs to be at the parameter level since the IN searchType has many parameters :)
  for $parm in $inputCopy3//fq:parameter
    return insert node attribute dtsFlag {$fqt:NO} into $parm
  ,
  (: Insert Alias Key as Parameter Attribute if Parameter Starts With Alias :)
  (: Every Alias Key should be Unique within the Entire Input XML, including SubQuery :)
  for $alias in $inputCopy3//fq:alias
    let $aliasKey := $alias/fq:key/text()
    for $parm in $inputCopy3//fq:parameter
      let $parmText := $parm/text()
      return 
        if (starts-with($parmText,concat($aliasKey,'.')))then
          insert node attribute aliasKey {$aliasKey} into $parm
        else()

) (: End Modify :)
return $inputCopy3

(: END Function :)
};


(:==================================================================:)
(: Translate Single Criteria                                        :)
(:==================================================================:)
declare function fqt:transSingleCriteria($inputXML as document-node(), 
                                         $targetNamespaceId as xs:string)
{ (: BEGIN FUNCTION :)

  (: DO NOT REMOVE THESE COMMENTS HERE! :)
  (: There are 3 things we need to do here :)
  (: Process Singles at the Most Outer Level :)
  (: Process Singles at SubQuery Outer Level :)
  (: Process Singles Inside Each SubQuery :)

  (: We can do the above 3 things in 2 Transformation steps :)
  (: We need to separate the Transformations because the Pending Update List will Conflict with each other :)

(: BEGIN FIRST XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (
  
  (: IMPORTANT!!! Use this FLWOR to DEBUG the Single Criteria :)
  (: The Single Criteria may contain an ENTIRE SubQuery! :)
  (: for $criteria in $inputCopy//fq:criteria[@transFlag = "N"] :)
  (:  return :)
  (:  replace node $criteria with <MO_DEBUG_SINGLE_CRITERIA>{$criteria}</MO_DEBUG_SINGLE_CRITERIA> :)

  (: For Criterias that are NOT SubQuery Outer Criteria :)
  (: Meaning all the Atomic (No Children) Criterias :)
  for $atomicCriteria in $inputCopy//fq:criteria[@transFlag=$fqt:NO and not(fq:query)]
    (: DEBUG :)
    (: return replace value of node $atomicCriteria/@transFlag with 'MO' :)
    return
      replace node $atomicCriteria with
      fqt:transCriteria($atomicCriteria,$fqt:FURTHER,$targetNamespaceId,$fqt:EMPTY,$fqt:EMPTY)

)
(: Return to a Second Transformation :)

return
(: BEGIN Second XQUERY TRANSFORMATION :)
(: Make a copy of the First Document :)
copy $inputCopy2 := $inputCopy
modify (
  
  (: IMPORTANT!!! Use this FLWOR to DEBUG the Single Criteria :)
  (: The Single Criteria may contain an ENTIRE SubQuery! :)
  (: for $criteria in $inputCopy2//fq:criteria[@transFlag = "N"] :)
  (:  return :)
  (:  replace node $criteria with <MO_DEBUG_SINGLE_CRITERIA>{$criteria}</MO_DEBUG_SINGLE_CRITERIA> :)
  
  (: Process the Outer Criteria for each SubQuery :)
  for $subQueryCriteria in $inputCopy2//fq:criteria[@transFlag=$fqt:NO and fq:query]
    (: DEBUG :)
    (: return replace value of node $subQueryCriteria/@transFlag with 'MO' :)
    return
      replace node $subQueryCriteria with
      fqt:transCriteria($subQueryCriteria,$fqt:FURTHER,$targetNamespaceId,$fqt:EMPTY,$fqt:EMPTY)

)
return $inputCopy2

(: END XQUERY TRANSFORMATION :)
};


(:==================================================================:)
(: Translate Criteria Details                                       :)
(: criteriaType & criteriaTypeNmspcId are Optional (Can be Blank)   :)
(:==================================================================:)
declare function fqt:transCriteria($criteria as node(),
                                   $srcNamespaceId as xs:string,
                                   $tgNamespaceId as xs:string,
                                   $criteriaType as xs:string?,
                                   $criteriaTypeNmspcId as xs:string?)
{ (: BEGIN FUNCTION :)

copy $c := $criteria
modify (

  (: Get Search Type for Current Criteria Node :)
  let $searchType := upper-case($c/fq:searchType)
  
  (: Switch Case to Select which Parameters to Process Based on Search Type :)
  (: Switch Requires XQuery 1.1 or Above, but is easier to read and more scalable :)
  return
    switch ($searchType)
      case 'SIMPLE' 
        (: Parameter[2]=Attribute Name, 3 = Attribute Value :)
        (: return ($criteria/parameters/parameter[2],$criteria/parameters/parameter[3]) :)
        return (
 
          (: Get the Source Attribute Name :)
          let $sourceAttrText := $c/fq:parameters/fq:parameter[2]/text()
          let $sourceAttrName :=
            if ($c/fq:parameters/fq:parameter[2 and @aliasKey]) then
              let $aliasKey := fn:string($c/fq:parameters/fq:parameter[2]/@aliasKey)
              return substring-after($sourceAttrText, concat($aliasKey,'.') )
            else             
              $sourceAttrText
           
           (: Strip out the Last Token in the Attribute Text :)
           (: tokenize will return the entire string if separator is not found in string,
           whereas string-after or string-after-last will return empty string.
           Therefore, use tokenize and get the last token. Cool! :)
           (: Data Format = RootEntity.TableName.AttributeName :)
           (: The sourceAttrName needs to be set here so i can reference it in the return fn:replace :)
           (: let $sourceAttrName := fn:tokenize($sourceAttrText,'\.')[last()] :)
           (: let $mdrResponse := fqt:getMDRAttrURL($sourceAttrName,$fqt:FURTHER,$tgNamespaceId) :)
  
           (: There should ONLY be ONE Result per source Attribute :)
           (: if there is more than one result, the criteriaType will determine which result is appropriate :)
           let $mdrResult := fqt:getMDRResult($sourceAttrName,$fqt:FURTHER,$tgNamespaceId,$criteriaType)
           
           (: DEBUG :)
           let $mdrURL := fqt:getMDRAttrURL($sourceAttrName,$fqt:FURTHER,$tgNamespaceId)
           (: let $mdrTranslatedAttrName := 'Translated MDR Parm2 Name' :)
           
           return (
            
             (: DEBUG
             replace value of node $c/fq:parameters/fq:parameter[2] 
                with $mdrURL :)

             (: if there is a Result, ALWAYS Set translatedAttrName (Except for SKIP) :)
             (: The datatype for attribute name is always String, 
                so there is no need for that Translation :)
             if ($mdrResult[translatedAttribute]) then
               
               (: if need to skip, update mdrFlag as fqt:SKIP :)
               if ($mdrResult/properties/entry[key=$fqt:ATTR_TRANS_FUNC and value=$fqt:skipATTR]) then
                 replace value of node $c/@mdrFlag with $fqt:SKIP
               (: Error Out devNull Associations AFTER checking for Skipped :)
               else if ($mdrResult/translatedAttribute=$fqt:devNull) then
                 replace value of node $c/@mdrFlag with $fqt:ERROR
               else
               
                 (: Get the Translated Attribute :)
                 let $translatedAttrName := $mdrResult/translatedAttribute/text()
                 
                 return (
                   replace value of node $c/fq:parameters/fq:parameter[2]
                      with fn:replace($sourceAttrText,$sourceAttrName,$translatedAttrName)
                      (: with $mdrURL :)
                   ,
                   replace value of node $c/@mdrFlag with $fqt:YES
                   
                   , (: Check for More Criteria :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:MORE_CRITERIA]
                     let $propVal := $entry/value
                     (: Get the Extra Criteria into an XML Attribute for later processing,
                        Because we cannot simply APPEND a <criteria> onto another here. 
                        We will process this XML Attribute moreCriteria in the transMoreCriteria Function :)
                     return insert node attribute moreCriteria {$propVal} into $c
                   
                   , (: Check for New Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:ATTR_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute attrAlias {$propVal} into $c/fq:parameters/fq:parameter[2]
                     
                   , (: Check for Extra Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:EXTRA_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute extraAlias {$propVal} into $c/fq:parameters/fq:parameter[2]

                 )                   
             else (
               replace value of node $c/@mdrFlag with $fqt:ERROR
               (: DEBUG :)
               (: replace value of node $c/fq:parameters/fq:parameter[2]
                  with concat('Debug_No_MDR_Translation_For=',$sourceAttrName) :)
             )
             
             , (: Process Code Translation Next :)
  
             (: Determine if we need to Call DTS to Translate Coded Value :)
             (: Skip the parameters with preTranslation Errors :)
             if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:translateCode]
                 and $c/fq:parameters/fq:parameter[3]/@dtsFlag!=$fqt:ERROR) then 
             
               let $dtsSrcPropVal := $c/fq:parameters/fq:parameter[3]/text()
               
               (: Determine the Source Namespace ID since one is for the code, and the other is for the type :)
               (: This ONLY Happens to SIMPLE, Since that is where the Phrases Occur :)
               let $srcNamespaceId := 
                 if ($sourceAttrName = 'observationType') then 
                   $criteriaTypeNmspcId
                 else 
                   $srcNamespaceId
               
               (: Call DTS :)
               let $dtsResponse := further:getTranslatedConcept($srcNamespaceId,
                                                                $fqt:dtsSrcPropNm,
                                                                $dtsSrcPropVal,
                                                                $tgNamespaceId,
                                                                $fqt:dtsTgPropName)
               (: DEBUG DTS URL :)
               (: let $dtsURL := further:getConceptTranslationRestUrl($srcNamespaceId,
                                                                   $fqt:dtsSrcPropNm,
                                                                   $dtsSrcPropVal,
                                                                   $tgNamespaceId,
                                                                   $fqt:dtsTgPropName) :)
                                                                
               (: let $debug := concat($srcNamespaceId,'|',
                                    $fqt:dtsSrcPropNm,'|',
                                    $dtsSrcPropVal,'|',
                                    $tgNamespaceId,'|',
                                    $fqt:dtsTgPropName) :)
                                    
               (: let $translatedPropVal := $dtsResponse/dts:concepts/dts:conceptId/propertyValue/text() :)
               let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)
               
               return
                 (: DEBUG
                 replace value of node $c/fq:parameters/fq:parameter[3]
                      with $dtsURL :)
                 
                 if ($translatedPropVal) then (
                   replace value of node $c/fq:parameters/fq:parameter[3]
                      with $translatedPropVal
                   ,
                   replace value of node $c/fq:parameters/fq:parameter[3]/@dtsFlag with $fqt:YES
                 )
                 else (
                   (: Always return Error if there is no DTS Mapping :)
                   replace value of node $c/fq:parameters/fq:parameter[3]/@dtsFlag with $fqt:ERROR,
                   (: Insert the Source Attribute Text as an XML Attribute for Error Handling :)
                   insert node attribute sourceAttrText {$sourceAttrText} into $c/fq:parameters/fq:parameter[3]
                 )
                 
             else if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:ageToBirthYear]) then 
             
               (: Get the Source Value to be Translated :)
               let $srcVal := $c/fq:parameters/fq:parameter[3]/text()  
               return
                 replace value of node $c/fq:parameters/fq:parameter[3]
                    with fqt:ageToBirthYear($srcVal)
             else()
            
             , (: Determine if we need to Translate the DataType :)
             (: WHY IS THERE NO ATTR_VALUE_TRANS_TO_DATA_TYPE in the MDR for the Attributes that NEEDS it! :)
             (: Try ask Rick, maybe it is currently hard coded :)
             for $entry in $mdrResult//entry[key=$fqt:ATTR_VALUE_TRANS_TO_DATA_TYPE]
               let $newDataType := $entry/value/text()
               return replace value of node $c/fq:parameters/fq:parameter[3]/@xsi:type with $newDataType
  
             , (: Do More Stuff :)
             (: Always Set Translation Flag after Translation :)
             if ($mdrResult[translatedAttribute]) then
               replace value of node $c/@transFlag with $fqt:YES
             else replace value of node $c/@transFlag with $fqt:ERROR
             
           )
           
         ) (: END SIMPLE Return :)
       
       case 'BETWEEN' 
         (: Parameter[1]=Attribute Name, 2 & 3 = Attribute Value :)
         return (
           
           (: Get the Source Attribute Name :)
           let $sourceAttrText := $c/fq:parameters/fq:parameter[1]/text()
           let $sourceAttrName :=
             if ($c/fq:parameters/fq:parameter[1 and @aliasKey]) then
               let $aliasKey := fn:string($c/fq:parameters/fq:parameter[1]/@aliasKey)
               return substring-after($sourceAttrText, concat($aliasKey,'.') )
             else             
               $sourceAttrText
  
           (: Call MDR Web Service to Translate Attribute Name HERE :)
           let $mdrResult := fqt:getMDRResult($sourceAttrName,$fqt:FURTHER,$tgNamespaceId,$criteriaType)
           (: let $mdrURL := fqt:getMDRAttrURL($sourceAttrName,$fqt:FURTHER,$tgNamespaceId) :)
           (: let $translatedAttrName := 'Translated MDR Name' :)
  
           return (
             (: if there is a Result, ALWAYS Set translatedAttrName :)
             (: The datatype for attribute name is always String, 
                so there is no need for that Translation :)
             if ($mdrResult/.[translatedAttribute]) then
             
               (: if need to skip, update mdrFlag as fqt:SKIP :)
               if ($mdrResult/properties/entry[key=$fqt:ATTR_TRANS_FUNC and value=$fqt:skipATTR]) then
                 replace value of node $c/@mdrFlag with $fqt:SKIP
               (: Error Out devNull Associations AFTER checking for Skipped :)
               else if ($mdrResult/translatedAttribute=$fqt:devNull) then
                 replace value of node $c/@mdrFlag with $fqt:ERROR
               else
                 let $translatedAttrName := $mdrResult/translatedAttribute/text()
                 return (
                   replace value of node $c/fq:parameters/fq:parameter[1] 
                      with fn:replace($sourceAttrText,$sourceAttrName,$translatedAttrName)
                   ,
                   replace value of node $c/@mdrFlag with $fqt:YES
                   
                   , (: Check for More Criteria :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:MORE_CRITERIA]
                     let $propVal := $entry/value
                     (: Get the Extra Criteria into an XML Attribute for later processing,
                        Because we cannot simply APPEND a <criteria> onto another here. 
                        We will process this XML Attribute moreCriteria in the transMoreCriteria Function :)
                     return insert node attribute moreCriteria {$propVal} into $c
                   
                   , (: Check for New Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:ATTR_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute attrAlias {$propVal} into $c/fq:parameters/fq:parameter[1]
                     
                   , (: Check for Extra Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:EXTRA_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute extraAlias {$propVal} into $c/fq:parameters/fq:parameter[1]

                 )
             else (
               replace value of node $c/@mdrFlag with $fqt:ERROR
               (: DEBUG :)
               (: replace value of node $c/fq:parameters/fq:parameter[1]
                  with concat('Debug_No_MDR_Translation_For=',$sourceAttrName) :)
             )
             
             , (: Process Code Translation Next Parameters 2 & 3 :)
  
             (: Determine if we need to Call DTS to Translate Coded Value :)
             if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:translateCode]) then 
             
               let $dtsSrcPropVal2 := $c/fq:parameters/fq:parameter[2]/text()
               let $dtsSrcPropVal3 := $c/fq:parameters/fq:parameter[3]/text()
                               
               (: Call DTS for Parameter 2 :)
               let $dtsResponse2 := further:getTranslatedConcept($srcNamespaceId,
                                                                 $fqt:dtsSrcPropNm,
                                                                 $dtsSrcPropVal2,
                                                                 $tgNamespaceId,
                                                                 $fqt:dtsTgPropName)
                                                                
               (: Call DTS for Parameter 3 :)
               let $dtsResponse3 := further:getTranslatedConcept($srcNamespaceId,
                                                                 $fqt:dtsSrcPropNm,
                                                                 $dtsSrcPropVal3,
                                                                 $tgNamespaceId,
                                                                 $fqt:dtsTgPropName)
               (: Debug DTS URL :)
               (: let $dtsURL := further:getConceptTranslationRestUrl($srcNamespaceId,
                                                                   $fqt:dtsSrcPropNm,
                                                                   $dtsSrcPropVal2,
                                                                   $tgNamespaceId,
                                                                   $fqt:dtsTgPropName) :)
  
               (: let $debug := concat($srcNamespaceId,'|',
                                    $fqt:dtsSrcPropNm,'|',
                                    $dtsSrcPropVal2,'|',
                                    $tgNamespaceId,'|',
                                    $fqt:dtsTgPropName) :)
  
               let $translatedPropVal2 := further:getConceptPropertyValue($dtsResponse2)
               let $translatedPropVal3 := further:getConceptPropertyValue($dtsResponse3)
               
               return (

                 if ($translatedPropVal2) then (
                   replace value of node $c/fq:parameters/fq:parameter[2] with $translatedPropVal2,
                   replace value of node $c/fq:parameters/fq:parameter[2]/@dtsFlag with $fqt:YES
                 )
                 else (
                   replace value of node $c/fq:parameters/fq:parameter[2]/@dtsFlag with $fqt:ERROR,
                   (: Insert the Source Attribute Text as an XML Attribute for Error Handling :)
                   insert node attribute sourceAttrText {$sourceAttrText} into $c/fq:parameters/fq:parameter[2]
                 )
                 ,
  
                 if ($translatedPropVal3) then (
                   replace value of node $c/fq:parameters/fq:parameter[3] with $translatedPropVal3,
                   replace value of node $c/fq:parameters/fq:parameter[3]/@dtsFlag with $fqt:YES
                 )
                 else (
                   replace value of node $c/fq:parameters/fq:parameter[3]/@dtsFlag with $fqt:ERROR,
                   (: Insert the Source Attribute Text as an XML Attribute for Error Handling :)
                   insert node attribute sourceAttrText {$sourceAttrText} into $c/fq:parameters/fq:parameter[3]
                 )
  
               ) (: End Replace Return :)
               
             else if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:ageToBirthYear]) then 
             
               (: Get the Source Value to be Translated :)
               let $srcValue2 := $c/fq:parameters/fq:parameter[2]/text()
               let $srcValue3 := $c/fq:parameters/fq:parameter[3]/text()
  
               (: Reverse the Order of 2 & 3 for this Special Case Since the Smaller BirthYear Must come First :)                        
               return (
                 replace value of node $c/fq:parameters/fq:parameter[2]
                    with fqt:ageToBirthYear($srcValue3),
                 replace value of node $c/fq:parameters/fq:parameter[3]
                    with fqt:ageToBirthYear($srcValue2)
               )
             
             else()
               
             , (: Determine if we need to Translate the DataType :)
             (: WHY IS THERE NO ATTR_VALUE_TRANS_TO_DATA_TYPE in the MDR for the Attributes that NEEDS it! :)
             (: Try ask Rick, maybe it is currently hard coded :)
             for $entry in $mdrResult//entry[key=$fqt:ATTR_VALUE_TRANS_TO_DATA_TYPE]
               let $newDataType := $entry/value/text()
               return (
                 replace value of node $c/fq:parameters/fq:parameter[2]/@xsi:type with $newDataType
                 ,
                 replace value of node $c/fq:parameters/fq:parameter[3]/@xsi:type with $newDataType
               )
               
             , (: Do More Stuff :)
             (: Always Set Translation Flag after Translation :)
             if ($mdrResult[translatedAttribute]) then
               replace value of node $c/@transFlag with $fqt:YES
             else replace value of node $c/@transFlag with $fqt:ERROR
           
           ) (: End Second Return :)
           
         ) (: End BETWEEN Return :)
                  
       case 'LIKE' 
         (: Parameter[1]=Attribute Name, Parameter[2] = Attribute Value :)
         return (
  
           (: Get the Source Attribute Name :)
           let $sourceAttrText := $c/fq:parameters/fq:parameter[1]/text()
           let $sourceAttrName :=
             if ($c/fq:parameters/fq:parameter[1 and @aliasKey]) then
               let $aliasKey := fn:string($c/fq:parameters/fq:parameter[1]/@aliasKey)
               return substring-after($sourceAttrText, concat($aliasKey,'.') )
             else             
               $sourceAttrText
           (:
           let $sourceAttrText := $c/fq:parameters/fq:parameter[1]/text()
           let $sourceAttrName := fn:tokenize($sourceAttrText,'\.')[last()]
           :)
           (: Call MDR Web Service to Translate Attribute Name HERE :)
           let $mdrResult := fqt:getMDRResult($sourceAttrName,$fqt:FURTHER,$tgNamespaceId,$criteriaType)
           (: let $mdrURL := fqt:getMDRAttrURL($sourceAttrName,$fqt:FURTHER,$tgNamespaceId) :)
           (: let $translatedAttrName := 'Translated MDR Name' :)
           return (
             if ($mdrResult/.[translatedAttribute]) then 
             
               (: if need to skip, update mdrFlag as fqt:SKIP :)
               if ($mdrResult/properties/entry[key=$fqt:ATTR_TRANS_FUNC and value=$fqt:skipATTR]) then
                 replace value of node $c/@mdrFlag with $fqt:SKIP
               (: Error Out devNull Associations AFTER checking for Skipped :)
               else if ($mdrResult/translatedAttribute=$fqt:devNull) then
                 replace value of node $c/@mdrFlag with $fqt:ERROR
               else
                 let $translatedAttrName := $mdrResult/translatedAttribute/text()
                 return (
                   replace value of node $c/fq:parameters/fq:parameter[1]
                           with fn:replace($sourceAttrText,$sourceAttrName,$translatedAttrName)
                   ,
                   replace value of node $c/@mdrFlag with $fqt:YES
                   
                   , (: Check for More Criteria :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:MORE_CRITERIA]
                     let $propVal := $entry/value
                     (: Get the Extra Criteria into an XML Attribute for later processing,
                        Because we cannot simply APPEND a <criteria> onto another here. 
                        We will process this XML Attribute moreCriteria in the transMoreCriteria Function :)
                     return insert node attribute moreCriteria {$propVal} into $c
                   
                   , (: Check for New Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:ATTR_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute attrAlias {$propVal} into $c/fq:parameters/fq:parameter[1]
                     
                   , (: Check for Extra Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:EXTRA_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute extraAlias {$propVal} into $c/fq:parameters/fq:parameter[1]

                 )
             else (
               replace value of node $c/@mdrFlag with $fqt:ERROR
               (: DEBUG :)
               (: replace value of node $c/fq:parameters/fq:parameter[1]
                  with concat('Debug_No_MDR_Translation_For=',$sourceAttrName) :)
             )
             
             , (: Comma to Separate Sequence Items :)
  
             (: Determine if we need to Call DTS to Translate Coded Value :)
             if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:translateCode]) then 
             
               let $dtsSrcPropVal := $c/fq:parameters/fq:parameter[2]/text()
               
               (: Call DTS :)
               let $dtsResponse := further:getTranslatedConcept($srcNamespaceId,
                                                                $fqt:dtsSrcPropNm,
                                                                $dtsSrcPropVal,
                                                                $tgNamespaceId,
                                                                $fqt:dtsTgPropName)
               (: Debug DTS URL :)
               (: let $dtsURL := further:getConceptTranslationRestUrl($srcNamespaceId,
                                                                   $fqt:dtsSrcPropNm,
                                                                   $dtsSrcPropVal,
                                                                   $tgNamespaceId,
                                                                   $fqt:dtsTgPropName) :)
                                                                
               (: let $dtsResponse := fqt:getDTSAttrValue($srcNamespaceId,$fqt:dtsSrcPropNm,$dtsSrcPropVal,$tgNamespaceId,$fqt:dtsTgPropName) :)
               (: let $translatedPropVal := 'Translated MDR Parm3 Value' :)
               
               (: let $debug := concat($srcNamespaceId,'|',
                                    $fqt:dtsSrcPropNm,'|',
                                    $dtsSrcPropVal,'|',
                                    $tgNamespaceId,'|',
                                    $fqt:dtsTgPropName) :)
                                    
               (: let $translatedPropVal := $dtsResponse/dts:concepts/dts:conceptId/propertyValue/text() :)
               let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)
               
               return
                 if ($translatedPropVal) then (
                   replace value of node $c/fq:parameters/fq:parameter[2]
                      with $translatedPropVal
                   ,
                   replace value of node $c/fq:parameters/fq:parameter[2]/@dtsFlag with $fqt:YES
                 )
                 else (
                   replace value of node $c/fq:parameters/fq:parameter[2]/@dtsFlag with $fqt:ERROR,
                   (: Insert the Source Attribute Text as an XML Attribute for Error Handling :)
                   insert node attribute sourceAttrText {$sourceAttrText} into $c/fq:parameters/fq:parameter[2]
                 )
             else if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:ageToBirthYear]) then 
             
               (: Get the Source Value to be Translated :)
               let $srcVal := $c/fq:parameters/fq:parameter[2]/text()
               return
                 replace value of node $c/fq:parameters/fq:parameter[2]
                    with fqt:ageToBirthYear($srcVal)
  
             else()
             
             , (: Determine if we need to Translate the DataType :)
             (: WHY IS THERE NO ATTR_VALUE_TRANS_TO_DATA_TYPE in the MDR for the Attributes that NEEDS it! :)
             (: Try ask Rick, maybe it is currently hard coded :)
             for $entry in $mdrResult//entry[key=$fqt:ATTR_VALUE_TRANS_TO_DATA_TYPE]
               let $newDataType := $entry/value/text()
               return replace value of node $c/fq:parameters/fq:parameter[2]/@xsi:type with $newDataType
  
             , (: Do More Stuff :)
             (: Always Set Translation Flag after Translation :)
             if ($mdrResult[translatedAttribute]) then
               replace value of node $c/@transFlag with $fqt:YES
             else replace value of node $c/@transFlag with $fqt:ERROR
             
           ) (: End Second Return :)
           
         ) (: End LIKE Return :)
       
       case 'IN'
         (: Parameter[1]=Attribute Name, Multiple Attribute Values :)
         return(
           
           (: Get the Source Attribute Name :)
           let $sourceAttrText := $c/fq:parameters/fq:parameter[1]/text()
           let $sourceAttrName :=
             if ($c/fq:parameters/fq:parameter[1 and @aliasKey]) then
               let $aliasKey := fn:string($c/fq:parameters/fq:parameter[1]/@aliasKey)
               return substring-after($sourceAttrText, concat($aliasKey,'.') )
             else             
               $sourceAttrText
               
           (:             
           let $sourceAttrText := $c/fq:parameters/fq:parameter[1]/text()
           let $sourceAttrName := fn:tokenize($sourceAttrText,'\.')[last()]
           :)
           (: Call MDR Web Service to Translate Attribute Name HERE :)
           let $mdrResult := fqt:getMDRResult($sourceAttrName,$fqt:FURTHER,$tgNamespaceId,$criteriaType)
           return (
             if ($mdrResult/.[translatedAttribute]) then
             
               (: if need to skip, update mdrFlag as fqt:SKIP :)
               if ($mdrResult/properties/entry[key=$fqt:ATTR_TRANS_FUNC and value=$fqt:skipATTR]) then
                 replace value of node $c/@mdrFlag with $fqt:SKIP
               (: Error Out devNull Associations AFTER checking for Skipped :)
               else if ($mdrResult/translatedAttribute=$fqt:devNull) then
                 replace value of node $c/@mdrFlag with $fqt:ERROR
               else
                 let $translatedAttrName := $mdrResult/translatedAttribute/text()
                 return (
                   replace value of node $c/fq:parameters/fq:parameter[1]
                      with fn:replace($sourceAttrText,$sourceAttrName,$translatedAttrName)
                   ,
                   replace value of node $c/@mdrFlag with $fqt:YES
                   
                   , (: Check for More Criteria :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:MORE_CRITERIA]
                     let $propVal := $entry/value
                     (: Get the Extra Criteria into an XML Attribute for later processing,
                        Because we cannot simply APPEND a <criteria> onto another here. 
                        We will process this XML Attribute moreCriteria in the transMoreCriteria Function :)
                     return insert node attribute moreCriteria {$propVal} into $c
                   
                   , (: Check for New Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:ATTR_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute attrAlias {$propVal} into $c/fq:parameters/fq:parameter[1]

                   , (: Check for Extra Aliases for Fields :)
                   for $entry in $mdrResult/properties/entry[key=$fqt:EXTRA_ALIAS]
                     let $propVal := $entry/value
                     (: Get the Alias into an XML Attribute for later processing,
                        We will process this XML Attribute alias in the transAlias Function :)
                     return insert node attribute extraAlias {$propVal} into $c/fq:parameters/fq:parameter[1]

                 )
             else (
               replace value of node $c/@mdrFlag with $fqt:ERROR
               (: DEBUG :)
               (: replace value of node $c/fq:parameters/fq:parameter[1]
                     with concat('Debug_No_MDR_Translation_For=',$sourceAttrName) :)
             )
  
             , (: Process DTS Stuff :)
             (: Determine if we need to Call DTS to Translate Coded Value :)
             if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:translateCode]) then 
  
               (: Process One Parameter at a Time, there could be many since this is the IN Operator :)
               (: The first parameter is the Attribute Name, the rest are Attribute Values :)
               (: Skip the parameters with preTranslation Errors :)
               for $parm in $c/fq:parameters/fq:parameter[position()>1 and @dtsFlag!=$fqt:ERROR]
                 
                 (:return
                 
                   if ($index>1) then 
                   
                     let $dtsSrcPropVal := $c/fq:parameters/fq:parameter[$index]/text():)
                   
                     (: Call DTS :)
                     let $dtsResponse := further:getTranslatedConcept($srcNamespaceId,
                                                                      $fqt:dtsSrcPropNm,
                                                                      $parm,
                                                                      $tgNamespaceId,
                                                                      $fqt:dtsTgPropName)
                     (: Debug DTS URL :)
                     (: let $dtsURL := further:getConceptTranslationRestUrl($srcNamespaceId,
                                                                         $fqt:dtsSrcPropNm,
                                                                         $parm,
                                                                         $tgNamespaceId,
                                                                         $fqt:dtsTgPropName) :)
                                                                 
                     let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)
                   
                     return
                     
                       (: DEBUG URL :)
                       (: replace value of node $parm with $dtsURL :)
                       
                       if ($translatedPropVal) then (
                         replace value of node $parm with $translatedPropVal
                         ,
                         replace value of node $parm/@dtsFlag with $fqt:YES
                       )
                       else (
                         replace value of node $parm/@dtsFlag with $fqt:ERROR,
                         (: Insert the Source Attribute Text as an XML Attribute for Error Handling :)
                         insert node attribute sourceAttrText {$sourceAttrText} into $parm
                       )
                       
             else if ($mdrResult/properties/entry[key=$fqt:ATTR_VALUE_TRANS_FUNC and value=$fqt:ageToBirthYear]) then 
             
               (: Get the Source Value to be Translated :)
               (: Process One Parameter at a Time, there could be many since this is the IN Operator :)
               for $param at $index in ($criteria/fq:parameters/*) 
           
                 (: The first parameter is the Attribute Name, the rest are Attribute Values :)
                 return
                 
                   if ($index>1) then
                     let $srcVal := $c/fq:parameters/fq:parameter[$index]/text()
                     return
                       replace value of node $c/fq:parameters/fq:parameter[$index]
                          with fqt:ageToBirthYear($srcVal)
  
                   else( (: End Inner IF :) )
  
             else( (: End Outter IF :) )
  
           , (: Determine if we need to Translate the DataType :)
           for $entry in $mdrResult//entry[key=$fqt:ATTR_VALUE_TRANS_TO_DATA_TYPE]
             let $newDataType := $entry/value/text()
             return
               (: Process One Parameter at a Time, there could be many since this is the IN Operator :)
               for $param at $index in ($criteria/fq:parameters/*) 
                 (: The first parameter is the Attribute Name, the rest are Attribute Values :)
                 return
                   if ($index>1) then
                     replace value of node $c/fq:parameters/fq:parameter[$index]/@xsi:type with $newDataType
                   else( (: DO NOTHING :) )
  
           , (: Do More Stuff :)
           (: Always Set Translation Flag after Translation :)
           if ($mdrResult[translatedAttribute]) then
             replace value of node $c/@transFlag with $fqt:YES
           else replace value of node $c/@transFlag with $fqt:ERROR
               
           ) (: End Second Return :)
             
         ) (: End IN Return :)
       
       default return <error>Invalid searchType in transCriteria function</error>
       (: End Switch Case :)
       
(: End Modify :)
)

(: Return Single Modified Criteria Node :)
return $c
(: END XQUERY TRANSFORMATION Function :)
};


(:==================================================================:)
(: transAlias = Translate Alias Stuff for Query                     :)
(:==================================================================:)
declare function fqt:transAlias($inputXML as document-node(),
                                $targetNamespaceId as xs:string)
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Must Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: Translate Aliases :)
  (: Must Translated the entire group of <aliases> at one time
     Because the replace cannot update single <alias> node with multiple <alias> nodes 
     It needs to be <aliases><alias></alias><alias></alias></aliases> :)
     
  (: The $index is used to differentiate each Alias Name :)
  for $alias at $index in $inputCopy//fq:alias
    
    (: Store Original Source Values :)
    let $associationObject := fn:string($alias/@associationObject)
    let $aliasKey := $alias/fq:key/text()
    let $aliasValue := $alias/fq:value/text()
    
    (: Get Translated Response from MDR for Target Namespace :)
    let $mdrResponse := fqt:getMDRAssoc($associationObject,$targetNamespaceId)

    (: Extract Out Translated Alias(es) :)
    let $translatedAlias := fqt:getAlias($mdrResponse,$index,$aliasKey,$targetNamespaceId)

    (: For Each Association :)
    (: Every Table Association Should have MDR PROPERTIES for ONE Key & Value Pair :)
    (: OLD CODE COMMENTED OUT
    let $mdrAssocObject := $mdrResponse/rightAsset/text()
    for $entry in $mdrResponse/properties/entry[key='ALIAS_KEY']
      let $mdrKey := <key>{concat( $entry/value/text(), fn:string($index) )}</key>
    for $entry in $mdrResponse/properties/entry[key='ALIAS_VALUE']
      let $mdrValue := <value>{$entry/value/text()}</value>
    :)
      
    (: EACH NODE ONLY BE REPLACED ONCE! does not work! :)
    return (

      (: Note :)
      (: Cannot use replace here since replace requires a valid xml document structure :)
      (: I just want to work with nodes here :)
      
      (: Remove Original Alias Node :)
      delete node $alias,
      
      (: Insert Translated Alias Node(s) for Each Original Alias Node :)
      (: Inserting into the Parent .. <aliases> node! :)
      insert node $translatedAlias into $alias/..
      
      (: Cannot use this since sometimes there are New Additional Nodes! :)
      (: There are one alias to many aliases relationships :)
      (:
      replace value of node $alias/@associationObject with $mdrAssocObject,
      replace value of node $alias/fq:key with $mdrKey,
      replace value of node $alias/fq:value with $mdrValue,
      :)
      
    ) (: End Return :)

) (: End Modify :)
return 

(: BEGIN Second XQUERY TRANSFORMATION :)
copy $inputCopy2 := $inputCopy
modify (
  
  (: Add Alias for Special Cases :)
  (: Use Case 1 = We are adding Aliases for New Criteria nodes Here :)
  (: Use Case 2 = Determin if Person translates to a Non-Person Table :)
  (: The Problem is that FURTHER Person fields do not have an Alias.
     So if it translates to a Non-Person Fields at the Target,
     We need to provide the target alias in the translated XML. 
     In the XML, we need to get from fieldName to targetAlias.fieldName :)
  (: For example, FURTHER.PERSON.VITAL_STATUS trans to OMOPv2.OBSERVATION_PERIOD.PERSON_STATUS_CONCEPT_ID :)
  (: We're not using this field for now, but would be nice to have this functionality in place :)
  
  (: We always want a new alias for these criteria,
     because each join requires a unique alias if 
     there are multiple joins to the same table,
     such as OpenMRS.personAttribute is overloaded with different
     types of values :)
     
  for $p at $i in $inputCopy2//fq:parameter[@attrAlias]
  let $key := substring-before($p/@attrAlias,$fqt:DELIMITER)
  let $val := substring-after($p/@attrAlias,$fqt:DELIMITER)
  return
  (: Insert into the First <query> parent, 
     therefore, 
     if the parameter is in a sub <query>,
     it will only insert into the <aliases> node within the same <query>, 
     without affecting outter <query> nodes!
     This is using the FIRST[1] ancestor XPath.
  :)
  if ($key and $val) then
	  insert node
	    <alias>
			  <key>{$key}</key>
				<value>{$val}</value>
			</alias>
	    into $p/ancestor::fq:query[1]//fq:aliases
  else()

) (: End Modify :)
return

(: BEGIN Third XQUERY TRANSFORMATION :)
copy $inputCopy3 := $inputCopy2
modify (
  
  (: Add Alias for Special Cases :)
  (: Use Case 1 = Sometimes we have an alias that translates to multiple aliases due to hierarchy relationship levels :)
  (: This EXCLUDES Observation Types Issues.
     For example, FURTHER.Order table translates to OpenMRS.Observation.Order table.
     Therefore, we need another alias to support the SubLevel.
     We need the Translated aliases to be like this, where the ord will go through observations object:
     <aliases>
		   <alias associationObject="Observations">
			   <key>obs</key>
			   <value>observations</value>
		   </alias>
		   <alias associationObject="Order">
			   <key>ord</key>
			   <value>obs.order</value>
		   </alias>
	   </aliases>
  :)
  
  (: For this situation, we DO NOT want the updateParmAlias function to update any parameter values.
     Therefore, I am doing this in a separate XQuery Transformation. 
     I know this tranAlias function is getting complex, We may want to redesign this in the future. :)

  for $p at $i in $inputCopy3//fq:parameter[@extraAlias]
  let $key := substring-before($p/@extraAlias,$fqt:DELIMITER)
  let $val := substring-after($p/@extraAlias,$fqt:DELIMITER)
  return
  (: Insert into the First <query> parent, 
     therefore, 
     if the parameter is in a sub <query>,
     it will only insert into the <aliases> node within the same <query>, 
     without affecting outter <query> nodes!
     This is using the FIRST[1] ancestor XPath.
  :)
  if ($key and $val) then
	  insert node
	    <alias>
			  <key>{$key}</key>
				<value>{$val}</value>
			</alias>
	    into $p/ancestor::fq:query[1]//fq:aliases
  else()

) (: End Modify :)
return $inputCopy3

(: END Function :)
};


(:==================================================================:)
(: transRoot = Translate rootObject                                 :)
(:==================================================================:)
declare function fqt:transRoot($inputXML as document-node(),
                               $targetNamespaceId as xs:string)
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Must Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: Querys and SubQuerys have rootObjects :)
  (: Therefore, For Each Query that has an rootObject XML Attribute :)
  for $query in $inputCopy//fq:query[@rootObject]
    
    (: Get the Original rootObject Value :)
    let $rootObject := fn:string($query/@rootObject)
    
    (: Get Translated Response from MDR :)
    let $mdrResponse := fqt:getMDRAssoc($rootObject,$targetNamespaceId)
    
    return 
      if ( $mdrResponse/assetAssociation[rightAsset] ) then
        
        (: DEBUG :)
        (: let $mdrRoot := concat('Translated_Root=',$rootObject) :)

        (: Strip out the Translated rootObject Value :)
        let $mdrRoot := $mdrResponse/assetAssociation/rightAsset/text()
        return replace value of node $query/@rootObject with $mdrRoot
    else ()
    
) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: getMDRAssoc = Get MDR Association as a Response XML              :)
(:==================================================================:)
declare function fqt:getMDRAssoc($assocObject as xs:string, $tgNmspcId as xs:string)
{ (: BEGIN FUNCTION :)

<assetAssociationList>
{
  (: let $baseURL := 'http://dev-esb.further.utah.edu:9000/mdr/rest/asset/association/left/translatesTo/' :)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/left/translatesTo/')
  let $docUrl := fn:concat( $baseURL, $assocObject )

  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  let $response := doc($parsedDocUrl)
  
  (: Get the Namespace Name so we can use it to strip out the correct assetAssociation :)
  let $tgNmspcName := further:getNamespaceName($tgNmspcId)
  
  (: Return the proper association(s) for the target Namespace :)
  for $assetAssociation in $response/mdr:assetAssociationList/assetAssociation[rightNamespace=$tgNmspcName]
    return $assetAssociation
}
</assetAssociationList>

(: End of FUNCTION :)
};


(:==================================================================:)
(: Validate (Error Handling)                                        :)
(:==================================================================:)
declare function fqt:validate($inputXML as document-node(),$tgNmspcName as xs:string)
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

  (: Error Out ANY 'LIKE' <searchType> Since we are not supporting at this time :)
  if ($inputCopy//fq:searchType='LIKE') then (
    
    (: Wish i could just replace, but did not work :)
    (: So I'm just deleting the whole file and then inserting the Error :)
    delete node $inputCopy//fq:query,
    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    for $c in ($inputCopy//fq:criteria[fq:searchType='LIKE'])[1]
      let $attrName := fqt:getAttrNameFromCriteria($c)
      return
      insert node
        <error xmlns="http://further.utah.edu/core/ws">
          <code>QUERY_TRANSLATION_ERROR</code>
          <message>LIKE searchType is not supported at this time.</message>
        </error>
        into $inputCopy 
  )
  
  (: Check for Non-Translated Criterias :)
  else if ($inputCopy//fq:criteria[@transFlag=$fqt:NO]) then (

    (: Wish i could just replace, but did not work :)
    (: So I'm just deleting the whole file and then inserting the Error :)
    delete node $inputCopy//fq:query,
    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    for $c in ($inputCopy//fq:criteria[@transFlag=$fqt:NO])[1]
      let $attrName := fqt:getAttrNameFromCriteria($c)
      return
      insert node
        <error xmlns="http://further.utah.edu/core/ws">
          <code>QUERY_TRANSLATION_ERROR</code>
          <message>Criteria [ {$fqt:FURTHeR}.{$attrName} ] NOT Tranlated</message>
        </error>
        into $inputCopy 
  )
  else if ($inputCopy//fq:criteria[@mdrFlag=$fqt:ERROR]) then (
    
    (: Wish i could just replace, but did not work :)
    (: So I'm just deleting the whole file and then inserting the Error :)
    delete node $inputCopy//fq:query,
    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    for $c in ($inputCopy//fq:criteria[@mdrFlag=$fqt:ERROR])[1]
      let $attrName := fqt:getAttrNameFromCriteria($c)
      return
      insert node
        <error xmlns="http://further.utah.edu/core/ws">
          <code>MDR_QUERY_TRANSLATION_ERROR</code>
          <message>MDR Association for [ {$fqt:FURTHeR}.{$attrName} ] May be Missing</message>
        </error>
        into $inputCopy 
  )
  else if ($inputCopy//fq:parameter[@dtsFlag=$fqt:ERROR]) then (
    
    (: Wish i could just replace, but did not work :)
    (: So I'm just deleting the whole file and then inserting the Error :)
    delete node $inputCopy//fq:query,
    (: Return the First Criteria that Errored so we do not have a long list of Errors :)
    (: Since the dtsFlag is at the parameter level, we can just search through the parameters, instead of criteria :)
    for $p in ($inputCopy//fq:criteria/fq:parameters/fq:parameter[@dtsFlag=$fqt:ERROR])[1]
    (: for $c in ($inputCopy//fq:criteria[fq:parameters/fq:parameter/@dtsFlag=$fqt:ERROR])[1] :)
      (: let $attrName := fqt:getAttrNameFromCriteria($c) :)
      (: Get the Source Attribute Name instead :)
      let $attrName := fn:data($p/@sourceAttrText)
      let $attrVal := fn:data($p)
      return
      insert node
        <error xmlns="http://further.utah.edu/core/ws">
          <code>DTS_QUERY_TRANSLATION_ERROR</code>
          <message>DTS Mapping for [ {$fqt:FURTHeR}.{$attrName}={$attrVal} ] May be Missing</message>
        </error>
        into $inputCopy
  )
  else(
    (: Remove ALL Criteria Nodes that have been SKIPPED :)
    (: This includes the criterias with 'NamespaceId' in it :)
    (: Exclude SubQuery's FIRST Criteria :)
    delete node $inputCopy//fq:criteria[(@transFlag=$fqt:SKIP or @mdrFlag=$fqt:SKIP) and not(fq:query)]
  ) (: End IF-Else Statement :)
  
) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: Cleanup                                                          :)
(:==================================================================:)
declare function fqt:cleanup($inputXML as document-node())
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (
  
  (: If the validate step did not Error Out.
     Meaning the <query> is still there.
     Then Process Cleanup.
     Otherwise we do not need to do anything. :)
  if ($inputCopy[fq:query]) then (
    
    (: Remove all Aliases that are not being used :)
    (: Sometimes one Source Alias translates to multiple target Aliases :)
    (: However, not all translated Aliases may be needed :)
    for $alias in $inputCopy//fq:alias[@oldAliasKey]
      let $key := $alias/fq:key
      return
        if (not(fn:exists($inputCopy//fq:parameter[fn:tokenize(.,'\.')[1]=$key]))) then
          delete node $alias
        else ()
    
    , (: Do more stuff :)
    
    (: Rename the criteria with @rootCriterion back to <rootCriterion> :)
    for $rc in $inputCopy//fq:criteria[@rootCriterion=$fqt:YES]
      return (
        rename node $rc as QName("http://further.utah.edu/core/query", "rootCriterion"),
        (: Delete rootCriterion Attribute :)
        delete node $rc/@rootCriterion
      )
      
    ,(: Do more stuff :)

    (: Delete ALL tranFlag Attributes on SUCCESS :)
    delete node $inputCopy//@transFlag,
    delete node $inputCopy//@mdrFlag,
    delete node $inputCopy//@dtsFlag

    ,(: Do more stuff :)

    (: Delete ALL aliasKey Attributes on SUCCESS :)
    delete node $inputCopy//@aliasKey,
    delete node $inputCopy//@oldAliasKey,
    delete node $inputCopy//@attrAlias,
    delete node $inputCopy//@extraAlias

    ,(: Do more stuff :)

    (: Delete ALL obsType Attributes on SUCCESS :)
    delete node $inputCopy//@obsType

   ,(: Do more stuff :)

    (: Delete moreCriteria Attributes on SUCCESS :)
    delete node $inputCopy//@moreCriteria

  )
  else( (: DO NOTHING :) )
  
) (: End Modify :)
return $inputCopy

(: END Function :)
};

(:==================================================================:)
(: getMDRResult = ALWAYS GET ONE MDR Attribute Translation RESULT   :)
(:==================================================================:)
declare function fqt:getMDRResult(
  $srcAttrName as xs:string,
  $srcNmspcId as xs:string,
  $tgNmspcId as xs:string,
  $criteriaType as xs:string?)
{ 
  (: EXAMPLE: ${server.mdr.ws}/mdr/rest/asset/association/unique/attribute/administrativeGender/FURTHeR/UUEDW :)
  (:          ${server.mdr.ws}/mdr/rest/asset/association/unique/attribute/{sourceAttr}/{sourceNamespace}/{targetNamespace} :)
  (:          http://dev-esb.further.utah.edu:9000/mdr/rest/asset/association/unique/attribute/administrativeGender/FURTHeR/UUEDW :)
  (: let $baseURL := 'http://dev-esb.further.utah.edu:9000/mdr/rest/asset/association/attribute/ :)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/attribute/')
  let $docUrl := fn:concat( $baseURL, $srcAttrName, '/', $srcNmspcId, '/', $tgNmspcId )

  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  let $doc := doc($parsedDocUrl)
  
  (: if there is more than one result, get the correct one based on the criteriaType :)
  return 
    if ( count($doc//attributeTranslationResult) > 1 ) then
      $doc/mdr:attributeTranslationResultList/attributeTranslationResult[properties/entry/value=$criteriaType]
    else 
      $doc/mdr:attributeTranslationResultList/attributeTranslationResult
};

(:==================================================================:)
(: getMDRAttrURL = Get URL for Debugging                            :)
(:==================================================================:)
declare function fqt:getMDRAttrURL(
  $srcAttrName as xs:string,
  $srcNmspcId as xs:string,
  $tgNmspcId as xs:string)
{ 
  (: EXAMPLE: ${server.dts.ws}/mdr/rest/asset/association/unique/attribute/administrativeGender/FURTHeR/UUEDW :)
  (:          ${server.dts.ws}/mdr/rest/asset/association/unique/attribute/{sourceAttr}/{sourceNamespace}/{targetNamespace} :)
  (:          http://dev-esb.further.utah.edu:9000/mdr/rest/asset/association/unique/attribute/administrativeGender/FURTHeR/UUEDW :)
  (: let $baseURL := 'http://dev-esb.further.utah.edu:9000/mdr/rest/asset/association/attribute/':)
  let $baseURL := fn:concat($const:fmdrRestServer,'/rest/asset/association/attribute/')
  let $docUrl := fn:concat( $baseURL, $srcAttrName, '/', $srcNmspcId, '/', $tgNmspcId )

  (: Prevent XQuery Injection Attacks :)
  let $parsedDocUrl := iri-to-uri( $docUrl )
  return $parsedDocUrl
};


(:==================================================================:)
(: printDebug = Print Debug Variable to Query Info Screen           :)
(:==================================================================:)
declare function fqt:printDebug($debugVar,$msg as xs:string?)
{
  let $var := $debugVar
  return fn:trace( $var,concat('DEBUG ', $msg, '=') )
};


(:==================================================================:)
(: ageToBirthYear = Translate Age to BirthYear                      :)
(:==================================================================:)
declare function fqt:ageToBirthYear($age)
{
  (: Get Current Year :)
  let $curYear := year-from-date(current-date())
  
  (: Subtract Age from CurrentYear to Get BirthYear :)
  return $curYear - $age
};


(:==================================================================:)
(: insertObsType = Set ObservationType Flag for later Processing    :)
(:==================================================================:)
declare function fqt:insertObsType($inputXML as document-node())
{
copy $inputCopy := $inputXML
modify (

  (: Loop through each Phrase :)
  for $criteriaPhrase in $inputCopy//*[fq:searchType/text()='CONJUNCTION' 
                                      and fq:criteria[fq:searchType/text()='SIMPLE' 
                                      and fn:contains(fq:parameters/fq:parameter[2]/text(),'observationNamespaceId')]]
                                      
    (: Get the observationType Value :)
    for $criteria in $criteriaPhrase/fq:criteria[fn:contains(fq:parameters/fq:parameter[2]/text(),'observationType')]
      let $criteriaType := $criteria/fq:parameters/fq:parameter[3]/text()
    
      (: Set ObservationType For Each 'observation' Related Parameters
         Including SIMPLE & IN searchTypes and observationType
         Since sometimes we do translate the observationType values :)
      (:for $parm in $criteriaPhrase/fq:criteria/fq:parameters/fq:parameter[fn:starts-with(fn:tokenize(.,'\.')[last()],'observation')]
        return insert node attribute obsType {$criteriaType} into $parm :)
        
      (: A better way may be, for every parameter that has an aliasKey attribute :)
      (: Because for Labs, there are parameters with non 'observation' words in it :)
      for $parm in $criteriaPhrase/fq:criteria/fq:parameters/fq:parameter[@aliasKey]
        return insert node attribute obsType {$criteriaType} into $parm

) (: End Modify :)
return $inputCopy
};


(:==================================================================:)
(: getAlias = Return Alias Node(s)                                  :)
(:==================================================================:)
declare function fqt:getAlias($mdrResponse,$outerIndex,$oldAliasKey,$tgNmspcId)
{ 
  (: Get the Namespace Name so we can use it to strip out the correct assetAssociation :)
  let $tgNmspcName := further:getNamespaceName($tgNmspcId)

  (: There can be more than one Object Assocations :)
  for $assoc at $innerIndex in $mdrResponse/assetAssociation[rightNamespace=$tgNmspcName]
    
    (: Create composite Index to Ensure it is Unique Since sometimes there could be multiple assocations
       We make each alias unique so we can better track each translated alias
       and we can treat each observation type differently during the updateParmAlias function.
       However, sometimes we may want to have Static Alias Key Values.
       Therefore, we have introduced the STATIC^Value Alias Key format. :)
    
    let $compositeIndex := concat($outerIndex,$innerIndex)

    (: Each Table Association MUST have MDR PROPERTIES for ONE Key & Value Pair :)
    let $mdrAssocObject := $assoc/rightAsset/text()
    for $entry in $assoc/properties/entry[key='ALIAS_KEY']
      (: pwkm 20150211
         Allow for Static Alias Keys for some External Data Sources.
         if static, use static MDR value, else use dynamic compositeIndex :)
      (: let $mdrKey := <key>{concat( $entry/value/text(), $compositeIndex )}</key> :)
      let $mdrKey := 
        if ( fn:contains($entry/value/text(), fn:concat($fqt:STATIC,$fqt:DELIMITER) ) ) then
           <key>{fn:tokenize($entry/value/text(),'\^')[last()]}</key>
        else
          <key>{concat( $entry/value/text(), $compositeIndex )}</key>

    for $entry in $assoc/properties/entry[key='ALIAS_VALUE']
      let $mdrValue := <value>{$entry/value/text()}</value>

		(: Return Alias Node(s) :)
		return
      if ($assoc/properties/entry[starts-with(key,'OBSERVATION_TYPE')]) then
		    (: Creates Multiple <alias> nodes if there are more than one OBSERVATION_TYPE entry :)
		    for $obsEntry in $assoc/properties/entry[starts-with(key,'OBSERVATION_TYPE')]
		    let $obsType := $obsEntry/value/text()
		    return <alias oldAliasKey='{$oldAliasKey}' obsType='{$obsType}' associationObject='{$mdrAssocObject}'>{$mdrKey}{$mdrValue}</alias>
		  else
		    <alias oldAliasKey='{$oldAliasKey}' associationObject='{$mdrAssocObject}'>{$mdrKey}{$mdrValue}</alias>

};


(:==================================================================:)
(: updateParmAlias = Update Alias in Parameters                     :)
(:==================================================================:)
declare function fqt:updateParmAlias($inputXML as document-node())
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Must Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: For Each Alias :)
  for $alias in $inputCopy//fq:alias[@oldAliasKey]
  
    (: Get the Old and New AliasKeys :)
    let $oldAliasKey := $alias/@oldAliasKey
    let $newAliasKey := $alias/fq:key/text()
    let $obsType := $alias/@obsType
    
    (: Replace Each Alias Attribute with the new Translated Alias Name :)
    (: Using the XQuery replace (case sensitive by default) function :)
    (: The middle parameter can be a Regular Expression, but we're currently using it as a string :)
    (: Appending a period at the end of the alias 
       To ensure that we are replacing the Table Alias and NOT the Table Attribute :)
    (: For example, if we had observation.observation in the parameter,
       Only the "observation." (with the period) will be replaced :)    
    (: Determine which Association to use if more than one :)
    
    return 
      if ($alias/.[@obsType]) then
        (: For Each Parameter with Observation Type, Update Alias Prefix :)
        for $parm at $index in $inputCopy//fq:parameter[@aliasKey=$oldAliasKey and @obsType=$obsType]
        return (
          replace value of node $parm with
          fn:replace($parm/text(), concat($oldAliasKey,'.'), concat($newAliasKey,'.') )
          

        )
      else
        (: For Each Parameter Non-Observation Types, Update Alias Prefix :)
        for $parm at $index in $inputCopy//fq:parameter[@aliasKey=$oldAliasKey]
        return (
          replace value of node $parm with
          fn:replace($parm/text(), concat($oldAliasKey,'.'), concat($newAliasKey,'.') )

        )

) (: End Modify :)
return

(: BEGIN Second XQUERY TRANSFORMATION for Field Aliases :)
copy $inputCopy2 := $inputCopy
modify (
  
  (: For Each Field Alias :)
  for $p in $inputCopy2//fq:parameter[@attrAlias]
  let $key := fn:substring-before($p/@attrAlias,$fqt:DELIMITER)
  return
    replace value of node $p with fn:concat($key,'.',$p)

) (: End Modify :)
return $inputCopy2

(: END Function :)
};


(:==================================================================:)
(: dedupAliases Remove Duplicate Aliases                            :)
(: Duplicate Aliases occur when a target table is overloaded        :)
(: Meaning One Source Table translates to Multiple Target Tables    :)
(: Intended to implement in cleanup function. 
   However it conflicts with the Update Pending List
   Therefore, needed to implement its own function                  :)
(:==================================================================:)

declare function fqt:dedupAliases($inputXML as document-node())
{
(: BEGIN XQUERY TRANSFORMATION :)
(: Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (
  
  (: Remove Duplicate Alias Nodes within the SAME <aliases> Node :)
  for $aliases in $inputCopy//fq:aliases
  
    (: This is some Tricky Stuff Right Here! :)  
    (: Select only one of its occurences,
       Such that its index in all Aliases is the same as the first index of its key in all keys. :)
    let $uniqueAliases := $aliases//fq:alias [index-of($aliases//fq:key, fq:key ) [1] ]
    return (
      delete node $aliases/fq:alias,
      insert node $uniqueAliases into $aliases
    )

) (: End Modify :)
return $inputCopy

(: END Function :)
};


(:==================================================================:)
(: Translate Criteria Phrase                                        :)
(: A Phrase consists of a group of criteria
   e.g. coded value that belongs to a coding terminology standard   :)
(:==================================================================:)
declare function fqt:transCriteriaPhrase($inputXML as document-node(), 
                                         $targetNamespaceId as xs:string){
(: BEGIN XQUERY TRANSFORMATION :)
(: Must Make a copy of the entire Document :)
copy $inputCopy := $inputXML
modify (

  (: Loop through each Phrase :)
  for $criteriaPhrase in $inputCopy//*[fq:searchType/text()='CONJUNCTION' 
                                      and fq:criteria[fq:searchType/text()='SIMPLE' 
                                      and fn:contains(fq:parameters/fq:parameter[2]/text(),'NamespaceId')]]
    
    (: Find each Namespace Group of Criterias, there could be more than one. :)
    for $criteriaNamespace in $criteriaPhrase/fq:criteria[fn:contains(fq:parameters/fq:parameter[2]/text(),'NamespaceId')]
    
      (: Get Source Namespace ID for this Group :)
      let $sourceNamespaceId := $criteriaNamespace/fq:parameters/fq:parameter[3]/text()
      (: Ensure that Java Fields follow consistent naming convention :)
      (: For example, field and fieldNamespaceId :)
      let $namespaceText := $criteriaNamespace/fq:parameters/fq:parameter[2]/text()
      let $namespaceField := substring-before(fn:tokenize($namespaceText,'\.')[last()],'NamespaceId')

      (: Get the Criteria Type if there is one :)
      let $criteriaType := 
        if ( $criteriaPhrase/fq:criteria[fn:contains(fq:parameters/fq:parameter[2]/text(),concat($namespaceField,'Type'))] ) then
          for $criteria in $criteriaPhrase/fq:criteria[fn:contains(fq:parameters/fq:parameter[2]/text(),concat($namespaceField,'Type'))]
          let $ctName := $criteria/fq:parameters/fq:parameter[2]/text()
          let $ctValue := $criteria/fq:parameters/fq:parameter[3]/text()
          return ($ctName,$ctValue)
        else
          $fqt:EMPTY
 
      (: Set the Namespace for the Type Code, Since the Type uses a separate NamespaceID :)
      let $criteriaTypeNmspcId := 
        if (fn:tokenize($criteriaType[1],'\.')[last()] = 'observationType')
        then $fqt:SNOMED
        else $fqt:EMPTY
 
      (: Note there needs to be a matching "name" from "name"NamespaceId above :)
      (:let $criteria := $criteriaPhrase/fq:criteria[fn:tokenize(fq:parameters/fq:parameter[2]/text(),'\.')[last()]=$namespaceField]:)
      return (
        
        (: Mark NamespaceId Criterias to be Skipped Since Target does not need them :)
        replace value of node $criteriaNamespace/@transFlag with $fqt:SKIP
        
        , (: Process Field Criteria for Namespace :)
        (: There may potentially be more than one observation within the SAME Phrase in the future :)
        (: SIMPLE searchType has the fieldName in parameter[2]
           Other searchType (such as 'IN') has the fieldName in parameter[1] :)
        for $criteria in $criteriaPhrase/fq:criteria[fn:tokenize(fq:parameters/fq:parameter[1]/text(),'\.')[last()]=$namespaceField
                                                     or
                                                     fn:tokenize(fq:parameters/fq:parameter[2]/text(),'\.')[last()]=$namespaceField]
        return replace node $criteria
           with fqt:transCriteria($criteria,$sourceNamespaceId,$targetNamespaceId,$criteriaType[2],$criteriaTypeNmspcId)
      
        , (: See if there is a Type such as observationType :)
        (: The Type only needs to be processed ONCE within one Phrase :)
        if ($criteriaPhrase/fq:criteria
          [ fn:tokenize(fq:parameters/fq:parameter[2]/text(),'\.')[last()]=concat($namespaceField,'Type')])
        then
          let $ct := $criteriaPhrase/fq:criteria
          [ fn:tokenize(fq:parameters/fq:parameter[2]/text(),'\.')[last()]=concat($namespaceField,'Type')]
          return 
          replace node $ct
           with fqt:transCriteria($ct,$sourceNamespaceId,$targetNamespaceId,$criteriaType[2],$criteriaTypeNmspcId)
        else()

        (: We can potentially Process the left over Single Criterias Here.
           However, I've decided to handle it in the transSingleCriteria function :)

      ) (: End Return :)
      
) (: End Modify :)
return $inputCopy
(: END XQUERY TRANSFORMATION :)
};


(:==================================================================:)
(: preTransOMOP                                                     :)
(: Pre-Translate ICD-9 Codes into SNOMED for OMOP Target ONLY!      :)
(: Since DTS Maps from ICD-9 to SNOMED, then to OMOP                :)
(: In the ideal world, if ICD-9 mapped to OMOP Directly             :)
(: we would not need this custom special function.                  :)
(:==================================================================:)
declare function fqt:preTransOMOP($inputXML as document-node(),
                                  $targetNamespaceId as xs:string)
{
copy $inputCopy := $inputXML
modify (

  (: For OMOP Targets ONLY! :)
  if ($targetNamespaceId = $fqt:OMOP-V2) then 

    (: Find Each ICD-9 Value :)
    for $criteriaGroup in $inputCopy//*[fq:searchType/text()='CONJUNCTION' 
                                        and fq:criteria[fq:searchType/text()='SIMPLE' 
                                        and fn:contains(fq:parameters/fq:parameter[2]/text(),'observationNamespaceId')
                                        and fq:parameters/fq:parameter[3]/text()=$fqt:ICD-9]]
       
      return (
      
      (: Replace NamespaceId to SNOMED :)
      for $criteria in $criteriaGroup/fq:criteria[fn:contains(fq:parameters/fq:parameter[2]/text(),'observationNamespaceId')]
        return replace value of node $criteria/fq:parameters/fq:parameter[3] with $fqt:SNOMED

      , (: Do more Stuff :)
      
      (: Note that ICD-9 Codes ONLY Occur in 'SIMPLE', or 'IN' searchTypes :)
      
      (: Strip out the observation value for SIMPLE searchType :)
      for $criteria in $criteriaGroup/fq:criteria[fn:tokenize(fq:parameters/fq:parameter[2],'\.')[last()] = 'observation'
                                                  and fq:searchType='SIMPLE']
        
        (: Get Source Attribute Text and Value :)
        let $sourceAttrText := $criteria/fq:parameters/fq:parameter[2]
        let $dtsSrcPropVal := $criteria/fq:parameters/fq:parameter[3]

        (: Call DTS :)
        let $dtsResponse := further:getTranslatedConcept($fqt:ICD-9,
                                                         $fqt:dtsSrcPropNm,
                                                         $dtsSrcPropVal,
                                                         $fqt:SNOMED,
                                                         $fqt:dtsSrcPropNm)
                                                         
        (: Debug DTS URL :)
        (:let $dtsURL := further:getConceptTranslationRestUrl($fqt:ICD-9,
                                                            $fqt:dtsSrcPropNm,
                                                            $dtsSrcPropVal,
                                                            $fqt:SNOMED,
                                                            $fqt:dtsSrcPropNm):)
       
        let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)
        
        (: if there is a response :)
        return
        if ($translatedPropVal) then
          replace value of node $criteria/fq:parameters/fq:parameter[3] with $translatedPropVal
        else (
          (: Mark for Error so we do not Translate Again in transCriteria Function :)
          replace value of node $criteria/fq:parameters/fq:parameter[3]/@dtsFlag with $fqt:ERROR,
          insert node attribute sourceAttrText {$sourceAttrText} into $criteria/fq:parameters/fq:parameter[3]
        )
          
      , (: Do more Stuff :)

      (: Strip out the observation value for IN searchType :)
      for $criteria in $criteriaGroup/fq:criteria[fn:tokenize(fq:parameters/fq:parameter[1],'\.')[last()] = 'observation'
                                                  and fq:searchType='IN']

        (: Get Source Attribute Name :)
        let $sourceAttrText := $criteria/fq:parameters/fq:parameter[1]

        (: For Parameters greater than the first position :)
        for $parm in $criteria/fq:parameters/fq:parameter[position()>1]

          (: Call DTS :)
          let $dtsResponse := further:getTranslatedConcept($fqt:ICD-9,
                                                           $fqt:dtsSrcPropNm,
                                                           $parm,
                                                           $fqt:SNOMED,
                                                           $fqt:dtsSrcPropNm)

          (: Debug DTS URL :)
          (:let $dtsURL := further:getConceptTranslationRestUrl($fqt:ICD-9,
                                                              $fqt:dtsSrcPropNm,
                                                              $parm,
                                                              $fqt:SNOMED,
                                                              $fqt:dtsSrcPropNm):)

          let $translatedPropVal := further:getConceptPropertyValue($dtsResponse)
        
          (: if there is a response :)
          return
          if ($translatedPropVal) then
            replace value of node $parm with $translatedPropVal
          else (
            (: Mark for Error so we do not Translate Again in transCriteria Function :)
            replace value of node $parm/@dtsFlag with $fqt:ERROR,
            insert node attribute sourceAttrText {$sourceAttrText} into $parm
          )
        
    ) (: End Return :)

  else( (: DO NOTHING if Target is NOT OMOP :) )
    
) (: End Modify :)
return $inputCopy
};


(:=====================================================================:)
(: Sanitize SINGLE & DOUBLE Quotes to Prevent XQuery Injection Attacks :)
(:=====================================================================:)
declare function fqt:sanitize($inputXML as document-node()) 
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

}; (: END OF FUNCTION fqt:sanitize :)


(:=====================================================================:)
(: getAttrNameFromCriteria                                             :)
(: Get the Attribute Name from a Single Criteria                       :)
(:=====================================================================:)
declare function fqt:getAttrNameFromCriteria($criteria as element()) 
as xs:string
{
  (: For SIMPLE searchType, it is always in the Second <parameter>
     Otherise, it is always in the First <parameter> :)
  let $attrName :=
    if ($criteria/fq:searchType = $fqt:SIMPLE) then
      $criteria/fq:parameters/fq:parameter[2]/text()
    else
      $criteria/fq:parameters/fq:parameter[1]/text()
  
  return $attrName

}; (: END OF FUNCTION fqt:getAttrNameFromCriteria :)


(:=====================================================================:)
(: transMoreCriteria                                                   :)
(: Add More Criteria if Any                                            :)
(:=====================================================================:)
declare function fqt:transMoreCriteria($inputXML as document-node()) 
as document-node()
{

(: BEGIN Transformation :)
copy $inputCopy := $inputXML
modify (

  for $translatedCriteria in $inputCopy//fq:criteria[@moreCriteria]
    (: Convert Property String into a Node, Awesome! :)
    let $content := fn:parse-xml($translatedCriteria/@moreCriteria)
    
    (: Since XQuery Transformations can only manipulate content that is within the inputCopy, 
       we need to call another function to fill the Template Contents. :)
    (: No can do this!
    for $templateCriteria in $content//fq:criteria[@moreCriteria="ReplaceMe"]
      return replace node $templateCriteria with $translatedCriteria
    :)
    
    return (

      replace node $translatedCriteria
         with fqt:fillContent($translatedCriteria,$content)
         
      (: We cannot delete and replace within the same Transformation, 
         So we will cleanup in the cleanup function instead. :)
      (: delete node $translatedCriteria/@moreCriteria :)
    )
      
) (: End Modify :)
return $inputCopy

}; (: END OF FUNCTION fqt:transMoreCriteria :)


(:=====================================================================:)
(: fillContent                                                         :)
(: Fill Template with Criteria Content                                 :)
(:=====================================================================:)
declare function fqt:fillContent($translatedCriteria,$template)
as document-node()
{

(: BEGIN Transformation :)
copy $templateCopy := $template
modify (
  
  (: Get the <criteria> in Template, and replace it with Translated Criteria :)
  for $c in $templateCopy//fq:criteria[@moreCriteria=$fqt:ReplaceMe]
    return (
      replace node $c with $translatedCriteria
      (: We cannot delete and replace within the same Transformation, 
         So we will cleanup in the cleanup function instead. :)
      (: delete node $c/@moreCriteria :)
    )

) (: End Modify :)
return $templateCopy

}; (: END OF FUNCTION fqt:fillTemplate :)

(: END OF MODULE :)
