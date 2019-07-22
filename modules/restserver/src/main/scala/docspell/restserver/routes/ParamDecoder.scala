package docspell.restserver.routes

import org.http4s.QueryParamDecoder
import org.http4s.dsl.impl.OptionalQueryParamDecoderMatcher

object ParamDecoder {

  implicit val booleanDecoder: QueryParamDecoder[Boolean] =
    QueryParamDecoder.fromUnsafeCast(qp => Option(qp.value).exists(_ equalsIgnoreCase "true"))("Boolean")

  object FullQueryParamMatcher extends OptionalQueryParamDecoderMatcher[Boolean]("full")


}
