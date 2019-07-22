package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait UserState
object UserState {
  val all = List(Active, Disabled)

  /** An active or enabled user. */
  case object Active extends UserState

  /** The user is blocked by an admin. */
  case object Disabled extends UserState


  def fromString(s: String): Either[String, UserState] =
    s.toLowerCase match {
      case "active" => Right(Active)
      case "disabled" => Right(Disabled)
      case _ => Left(s"Not a state value: $s")
    }

  def unsafe(str: String): UserState =
    fromString(str).fold(sys.error, identity)

  def asString(s: UserState): String = s match {
    case Active => "active"
    case Disabled => "disabled"
  }

  implicit val userStateEncoder: Encoder[UserState] =
    Encoder.encodeString.contramap(UserState.asString)

  implicit val userStateDecoder: Decoder[UserState] =
    Decoder.decodeString.emap(UserState.fromString)

}