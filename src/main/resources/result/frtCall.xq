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
(: import module namespace frt = "http://further.utah.edu/result-translation"
    at 'frt.xqm'; :)
import module namespace frt = "http://further.utah.edu/result-translation"
    at '${server.mdr.ws}${path.mdr.ws.resource.path}/result/frt.xqm';
       
(: ALWAYS PUT THIS IN THE XQUERY PROLOG! :)
declare namespace fn  = 'http://www.w3.org/2005/xpath-functions';
declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare namespace xsi = "http://www.w3.org/2001/XMLSchema-instance";
declare namespace fq = "http://further.utah.edu/core/query";

(: Turn On the Option to Output the <xml> heading on the first Line :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:omit-xml-declaration "no";

(: Set docName :)
declare variable $docName as document-node() external;

(: Get Source Namespace ID from External :)
declare variable $srcNmspcId as xs:string external;

(: Set DataSet ID :)
declare variable $dataSetId as xs:string external;

(: END PROLOG :)


(:==================================================================:)
(: Call Main Translate Query Function                               :)
(:==================================================================:)

(: Sanitize Data to Prevent XQuery Injection Attacks :)
let $sanitizedDoc := frt:sanitize($docName)

(: Use the Source Namespace ID instead of Namespace Name :)
return frt:transResult($sanitizedDoc,$srcNmspcId,$dataSetId)
