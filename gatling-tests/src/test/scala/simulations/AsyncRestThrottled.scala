package simulations

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

import scala.concurrent.duration._
import scala.language.postfixOps

class AsyncRestThrottled extends Simulation {

  val servicetUrl: String = System.getProperty("test.serviceUrl", "http://localhost:8888")

  val callRate: Int = Integer.getInteger("test.reqPerSec", 6000)
  val userCount: Int = Integer.getInteger("test.userCount", 500)
  val rampUpDuration: FiniteDuration = Duration(System.getProperty("test.rampUpDuration", "20 seconds")).asInstanceOf[FiniteDuration]
  val testDuration: FiniteDuration = Duration(System.getProperty("test.testDuration", "2 minutes")).asInstanceOf[FiniteDuration]
  val repeatCount: Int = testDuration.toMillis.toInt

  System.out.println()
  System.out.println("================================================================================")
  System.out.println(s"Call rate: $callRate req/s")
  System.out.println(s"User count: $userCount usr")
  System.out.println(s"Ramp up duration: $rampUpDuration")
  System.out.println(s"Test duration: $testDuration")
  System.out.println(s"Repeat count: $repeatCount req/usr")
  System.out.println(s"Ideal request count: ${testDuration.toSeconds.toInt * callRate + rampUpDuration.toSeconds.toInt * callRate / 2} req")
  System.out.println()

  val httpConf: HttpProtocolBuilder = http
    .baseUrl(servicetUrl)
    .acceptHeader("text/html,application/xhtml+xml,application/xml,application/json;q=0.9,*/*;q=0.8")
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0")

  val scn: ScenarioBuilder = scenario("AsyncHelloScenario")
    .repeat(repeatCount, "call-per-user") {
      exec(http("asynchello")
        .get(s"/asynchello")
        .check(status.is(200))
        .check(bodyString.is("Hello"))
      )
    }

  setUp(
    scn.inject(rampUsers(userCount) during rampUpDuration).throttle(
      reachRps(callRate) in rampUpDuration,
      holdFor(testDuration)
    )
  ).protocols(httpConf)

}
