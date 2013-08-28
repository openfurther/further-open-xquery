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

(: Change the location of fqt.xqm when working locally :)
(: import module namespace fqt = "http://further.utah.edu/query-translation"
    at 'fqt.xqm'; :)
import module namespace fqt = "http://further.utah.edu/query-translation"
       at '${server.mdr.ws}${path.mdr.ws.resource.path}/query/fqt.xqm';

(: ALWAYS PUT THIS IN THE XQUERY PROLOG! :)
declare namespace fn  = 'http://www.w3.org/2005/xpath-functions';
declare namespace xs = "http://www.w3.org/2001/XMLSchema";
declare namespace xsi = "http://www.w3.org/2001/XMLSchema-instance";
declare namespace fq = "http://further.utah.edu/core/query";

(: Turn On the Option to Output the <xml> heading on the first Line :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:omit-xml-declaration "no";

(: Get Target Namespace ID from External :)
declare variable $tgNmspcId as xs:string external;
declare variable $docName as document-node() external;

(: END PROLOG :)


(:==================================================================:)
(: Call Main Translate Query Function                               :)
(:==================================================================:)

(: Sanitize Data to Prevent XQuery Injection Attacks :)
let $sanitizedDoc := fqt:sanitize($docName)

(: Use the Target Namespace ID instead of Namespace Name :)
return fqt:transQuery($sanitizedDoc,$tgNmspcId)
