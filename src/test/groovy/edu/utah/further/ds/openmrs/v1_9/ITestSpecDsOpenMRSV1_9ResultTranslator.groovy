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
package edu.utah.further.ds.openmrs.v1_9

import org.custommonkey.xmlunit.DetailedDiff
import org.custommonkey.xmlunit.Diff
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Value
import org.springframework.test.context.ContextConfiguration

import spock.lang.Unroll
import edu.utah.further.core.test.xml.IgnoreNamedElementsDifferenceListener
import edu.utah.further.core.xml.xquery.XQueryService
import edu.utah.further.ds.test.translations.TranslationTest
import groovy.util.logging.Slf4j

/**
 * ...
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
 * @version Oct 8, 2013
 */
@ContextConfiguration(locations = [
	"/META-INF/ds/test/ds-test-mdr-ws-server-context.xml",
	"/META-INF/ds/test/ds-test-dts-ws-server-context.xml",
	"/META-INF/ds/test/ds-test-fqe-mpi-ws-server-context.xml",
	"/META-INF/ds/test/ds-test-xquery-context.xml",
	"/open-xquery-test-context.xml",
])
@Slf4j
class ITestSpecDsOpenMRSV1_9ResultTranslator extends TranslationTest
{
	@Autowired
	XQueryService xQueryService

	@Value('${server.mdr.ws}${path.mdr.ws.resource.path}/result/frtCall.xq')
	def url;

	@Unroll
	def "Testing OpenMRSv1.9 Result Translations: #name"() {
		given:
		def xQuery = url.toURL().text

		def parameters = ["srcNmspcId" : "32812", "dataSetId" : "1234"]
		def output = xQueryService.executeIntoString(
				new ByteArrayInputStream(xQuery.bytes), result, parameters)

		//no if debug is enabled jazz cuz groovy is cool like that (it does it for you)!
		log.debug("++++++++++++++++++++++++++++++++++++++++")
		log.debug(name);
		log.debug(output)
		log.debug("++++++++++++++++++++++++++++++++++++++++")

		expect:
		def diff = new DetailedDiff(new Diff(output, expected.text))
		diff.overrideDifferenceListener(new IgnoreNamedElementsDifferenceListener(["id", "compositeId"]))
		diff.similar()

		result.close()
		expected.close()


		where:
		result << queryFiles('/result-translator/openmrsv1_9/input/*').values()
		expected << queryFiles('/result-translator/openmrsv1_9/expected/*').values();
		name << queryFiles('/result-translator/openmrsv1_9/input/*').keySet()
	}
}
