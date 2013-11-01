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
 
module namespace com='http://further.utah.edu/commons';

declare function com:getNode()
{
  <node/>
};

declare function com:emptyNode()
{
  let $n := com:getNode()
  return $n/null
};

declare function com:add-commas-to-positive-integer ( $in as xs:string? ) as xs:string 
{
  if (string-length($in) < 4) then ($in)
  else (
        let $mod := string-length($in) mod 3
        let $prefix := if ($mod = 0) then (concat(substring($in, 1, 3), ',')) else (concat(substring($in, 1, $mod), ','))
        let $remainder :=  if ($mod = 0) then (substring($in, 4)) else (substring($in, $mod+1))
        return concat($prefix, com:add-commas-to-positive-integer(($remainder)))
     )
 } ;

