package docspell.backend.signup

import docspell.common._

final case class ExternalAccount(
    collName: Ident,
    login: Ident,
    source: AccountSource
) {

  def toAccountId: AccountId =
    AccountId(collName, login)
}
