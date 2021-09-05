package docspell.backend.signup
import docspell.common._

case class RegisterData(
    collName: Ident,
    login: Ident,
    password: Password,
    invite: Option[Ident]
)
