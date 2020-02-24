package docspell.analysis.contact

import cats.data.NonEmptyList
import docspell.common.LenientUri

case class Domain(labels: NonEmptyList[String], tld: String) {

  def asString: String =
    labels.toList.mkString(".") + tld

  def toPrimaryDomain: Domain =
    if (labels.tail.isEmpty) this
    else Domain(NonEmptyList.of(labels.last), tld)
}

object Domain {

  def domainFromUri(uri: String): Either[String, Domain] =
    LenientUri
      .parse(if (uri.contains("://")) uri else s"http://$uri")
      .flatMap(uri => uri.authority.toRight("Uri has no authoriry part"))
      .flatMap(auth => parse(auth))

  def parse(str: String): Either[String, Domain] =
    Tld
      .findTld(str)
      .map(tld => (str.dropRight(tld.length), tld))
      .map({
        case (names, tld) =>
          names.split('.').toList match {
            case Nil => Left(s"Not a domain: $str")
            case segs
                if segs.forall(label =>
                  label.trim.nonEmpty && label.forall(c => c.isLetter || c.isDigit || c == '-')
                ) =>
              Right(Domain(NonEmptyList.fromListUnsafe(segs), tld))
            case _ => Left(s"Not a domain: $str")
          }
      })
      .getOrElse(Left(s"Not a domain $str"))

  def isDomain(str: String): Boolean =
    parse(str).isRight
}
