/**
 * Copyright (C) [2013] [The FURTHeR Project]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package edu.utah.further.ds.omop.v2

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;

import org.custommonkey.xmlunit.XMLUnit;
import org.custommonkey.xmlunit.Diff;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.core.io.ClassPathResource
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.test.context.ContextConfiguration

import spock.lang.Specification
import spock.lang.Unroll
import edu.utah.further.core.qunit.xquery.XQueryAssertUtil;
import edu.utah.further.core.xml.xquery.XQueryService;
import edu.utah.further.core.xml.xquery.basex.XQueryServiceBaseXImpl
import edu.utah.further.mdr.ws.api.service.rest.AssetServiceRest;
import groovy.util.logging.Slf4j;


/**
 * Query translation tests against ds-test/src/main/resources/query-translator 
 * XML files (Logical FURTHeR Query) to expected OMOPv2 Query output.
 * <p>
 * -----------------------------------------------------------------------------------<br>
 * (c) 2008-2012 FURTHeR Project, Health Sciences IT, University of Utah<br>
 * Contact: {@code <further@utah.edu>}<br>
 * Biomedical Informatics, 26 South 2000 East<br>
 * Room 5775 HSEB, Salt Lake City, UT 84112<br>
 * Day Phone: 1-801-581-4080<br>
 * -----------------------------------------------------------------------------------
 *
 * @author N. Dustin Schultz {@code <dustin.schultz@utah.edu>}
 * @version Jul 3, 2013
 */
@ContextConfiguration(locations = [
	"/META-INF/ds/test/ds-test-mdr-ws-client-context.xml",
	"/META-INF/ds/test/ds-test-mdr-ws-server-context.xml",
	"/META-INF/ds/test/ds-test-dts-ws-server-context.xml",
	"/META-INF/ds/test/ds-test-xquery-context.xml",
	"/open-xquery-test-context.xml",
])
@Slf4j
class ITestSpecDsOmopV2QueryTranslator extends Specification {

	@Autowired
	XQueryService xQueryService

	@Autowired
	AssetServiceRest mdrAssetServiceRestClient

	def setup() {
		XMLUnit.setIgnoreWhitespace(true)
		XMLUnit.setIgnoreComments(true)
	}

	@Unroll
	def "Testing OMOPv2 Query Translations"() {
		given:
		def xQuery = mdrAssetServiceRestClient.getActiveResourceContentByPath("query/fqtCall.xq")

		def parameters = ["tgNmspcId" : "32868", "tgNmspcName" : "OMOP-V2"]
		def result = xQueryService.executeIntoString(
				new ByteArrayInputStream(xQuery.bytes), query, parameters)
		query.close()
		
		expect:
		new Diff(result, expected.text).similar()


		where:
		query << queryFiles('/query-translator/input/*')
		expected << queryFiles('/query-translator/omopv2/expected/*')
	}

	/**
	 * Returns an ORDERED list of inputstreams representing files at location.
	 *
	 * @return
	 */
	private def queryFiles(location) {
		def fileStreams = new PathMatchingResourcePatternResolver().getResources(location)
			.collectEntries(new TreeMap()){[it.filename, it.inputStream]}
		fileStreams.values()
	}
	
}