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
 
module namespace const='http://further.utah.edu/constants';

(: This file centralizes constants common to all XQuery programs, in particular :)
(: URLs to external services.                                                   :)

(: ================================================= :)
(: URLs                                              :)
(: ================================================= :)
(: FURTHeR terminology web services server URL :)
declare variable $const:restServer       := '${server.dts.ws}';

(: Terminology translation web services URL prefix :)
declare variable $const:dtsSearchService := '${path.dts.ws.search}';

(: Terminology translation web services URL prefix :)
declare variable $const:dtsRestService   := '${path.dts.ws.translate}';

(: MDR web services server URL :)
declare variable $const:fmdrRestServer   := '${server.mdr.ws}';
(: MDR resource-retrieval-by-path web service :)
declare variable $const:fmdrRestService  := '${path.mdr.ws.resource.path}';

(: ================================================= :)
(: MDR resource paths                                :)
(: ================================================= :)
declare variable $const:fmdrPathValueDomainsXmi := '/fqe/further/lm/valuedomains.xmi';
