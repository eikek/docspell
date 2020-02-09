package docspell.common

case class AccountId(collective: Ident, user: Ident) {

  def asString =
    s"${collective.id}/${user.id}"
}

object AccountId {
  private[this] val sepearatorChars: String = "/\\:"

  def parse(str: String): Either[String, AccountId] = {
    val input = str.replaceAll("\\s+", "").trim
    val invalid: Either[String, AccountId] =
      Left(s"Cannot parse account id: $str")

    def parse0(sep: Char): Either[String, AccountId] =
      input.indexOf(sep.toInt) match {
        case n if n > 0 && input.length > 2 =>
          val coll = input.substring(0, n)
          val user = input.substring(n + 1)
          Ident
            .fromString(coll)
            .flatMap(collId => Ident.fromString(user).map(userId => AccountId(collId, userId)))
        case _ =>
          invalid
      }

    val separated = sepearatorChars.foldRight(invalid) { (c, v) =>
      v.orElse(parse0(c))
    }

    separated.orElse(Ident.fromString(str).map(id => AccountId(id, id)))
  }
}
