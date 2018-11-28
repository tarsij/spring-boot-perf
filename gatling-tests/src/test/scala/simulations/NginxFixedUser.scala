package simulations

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

import scala.concurrent.duration._
import scala.language.postfixOps

class NginxFixedUser extends Simulation {

  val dockerPrefix: String = "" // "docker.for.mac."

  val servicetUrl: String = s"http://${dockerPrefix}localhost:32768"

  val callRate: Int = 8000
  val approxTestDuration: Duration = 2 minutes
  val meanResponseTime: Int = 10
  val responseDeviation: Int = 0

  val userCount: Int = callRate * meanResponseTime / 1000
  val repeatCount: Int = approxTestDuration.toMillis.toInt / meanResponseTime
  val minResponseTime: Int = meanResponseTime - responseDeviation
  val maxResponseTime: Int = meanResponseTime + responseDeviation + 1

  System.out.println(s"Call rate: $callRate req/s")
  System.out.println(s"User count: $userCount usr")
  System.out.println(s"Repeat count: $repeatCount req/usr")
  System.out.println(s"Min response time: $minResponseTime ms")
  System.out.println(s"Max response time: $maxResponseTime ms")
  System.out.println(s"Total request count: ${userCount * repeatCount} req")

  val httpConf: HttpProtocolBuilder = http
    .baseUrl(servicetUrl)
    .acceptHeader("text/html,application/xhtml+xml,application/xml,application/json;q=0.9,*/*;q=0.8")
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0")

  val scn: ScenarioBuilder = scenario("GetHelloScenario")
    .repeat(repeatCount, "call-per-user") {
      exec(http("hello")
        .get("")
        .check(status.is(200))
      )
    }

  setUp(
    scn.inject(atOnceUsers(userCount))
  ).protocols(httpConf)

}
