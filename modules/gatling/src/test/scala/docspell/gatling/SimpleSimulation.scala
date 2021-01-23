package docspell.gatling

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class SimpleSimulation extends Simulation {
  val cfg = Config.loaded

  val httpProtocol = http
    .baseUrl(cfg.baseUrl)
    .inferHtmlResources()

  val json        = Map("Content-Type" -> "application/json")
  val authBody    = RawFileBody("docspell/gatling/demo-auth.json")
  val emptySearch = RawFileBody("docspell/gatling/empty-search-form.json")

  val scn = scenario("SimpleSimulation")
    .exec(
      http("auth-login")
        .post("/api/v1/open/auth/login")
        .headers(json)
        .body(authBody)
        .resources(
          http("searchWithTags")
            .post("/api/v1/sec/item/searchWithTags")
            .body(emptySearch),
          http("searchStats")
            .post("/api/v1/sec/item/searchStats")
            .body(emptySearch)
        )
    )

  setUp(scn.inject(rampConcurrentUsers(1).to(20).during(10.seconds)))
    .protocols(httpProtocol)
}
