package docspell.restserver.http4s

import org.http4s.QueryParamDecoder
import org.http4s.ParseFailure
import docspell.common.ContactKind
import org.http4s.dsl.impl.OptionalQueryParamDecoderMatcher

object QueryParam {
  case class QueryString(q: String)

  implicit val contactKindDecoder: QueryParamDecoder[ContactKind] =
    QueryParamDecoder[String].emap(str =>
      ContactKind.fromString(str).left.map(s => ParseFailure(str, s))
    )

  implicit val queryStringDecoder: QueryParamDecoder[QueryString] =
    QueryParamDecoder[String].map(s => QueryString(s.trim.toLowerCase))

  // implicit val booleanDecoder: QueryParamDecoder[Boolean] =
  //   QueryParamDecoder.fromUnsafeCast(qp => Option(qp.value).exists(_.equalsIgnoreCase("true")))(
  //     "Boolean"
  //   )

  object FullOpt extends OptionalQueryParamDecoderMatcher[Boolean]("full")

  object ContactKindOpt extends OptionalQueryParamDecoderMatcher[ContactKind]("kind")

  object QueryOpt extends OptionalQueryParamDecoderMatcher[QueryString]("q")
}
