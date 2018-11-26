package simulations

import io.gatling.core.Predef._
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder

import scala.concurrent.duration._
import scala.language.postfixOps

class NginxFixedRate extends Simulation {

  val dockerPrefix : String = "" // "docker.for.mac."

  val servicetUrl : String = s"http://${dockerPrefix}localhost:32768"

  val callRate : Int = 500
  val approxTestDuration : FiniteDuration = 2 minutes

  val userCount : Int = callRate

  System.out.println(s"Call rate: $callRate req/s")
  System.out.println(s"User rate: $userCount usr/s")
  System.out.println(s"Total request count: ${callRate * approxTestDuration.toSeconds.toInt} req")

  val httpConf : HttpProtocolBuilder = http
    .baseUrl(servicetUrl)
    .acceptHeader("text/html,application/xhtml+xml,application/xml,application/json;q=0.9,*/*;q=0.8")
    .doNotTrackHeader("1")
    .acceptLanguageHeader("en-US,en;q=0.5")
    .acceptEncodingHeader("gzip, deflate")
    .userAgentHeader("Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0")

  val scn : ScenarioBuilder = scenario("GetHelloScenario")
    .exec(http("hello")
      .get("")
      .check(status.is(200))
    )

  setUp(
    scn.inject(constantUsersPerSec(userCount) during approxTestDuration)
  ).protocols(httpConf)

}
