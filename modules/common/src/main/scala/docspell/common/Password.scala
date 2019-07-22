package docspell.common

import io.circe.{Decoder, Encoder}

final class Password(val pass: String) extends AnyVal {

  def isEmpty: Boolean= pass.isEmpty

  override def toString: String =
    if (pass.isEmpty) "<empty>" else "***"

}

object Password {

  val empty = Password("")

  def apply(pass: String): Password =
    new Password(pass)

  implicit val passwordEncoder: Encoder[Password] =
    Encoder.encodeString.contramap(_.pass)

  implicit val passwordDecoder: Decoder[Password] =
    Decoder.decodeString.map(Password(_))

}
