package docspell.joex.notify

import yamusca.imports._
import yamusca.implicits._
import docspell.common._

trait YamuscaConverter {

  implicit val uriConverter: ValueConverter[LenientUri] =
    ValueConverter.of(uri => Value.fromString(uri.asString))

  implicit val timestamp: ValueConverter[Timestamp] =
    ValueConverter.of(ts => Value.fromString(ts.toUtcDate.toString))

  implicit val ident: ValueConverter[Ident] =
    ValueConverter.of(id => Value.fromString(id.id))

  implicit val account: ValueConverter[AccountId] =
    ValueConverter.deriveConverter[AccountId]

}

object YamuscaConverter extends YamuscaConverter
