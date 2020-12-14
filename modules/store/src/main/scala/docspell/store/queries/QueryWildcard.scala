package docspell.store.queries

object QueryWildcard {

  def lower(s: String): String =
    apply(s.toLowerCase)

  def apply(value: String): String = {
    def prefix(n: String) =
      if (n.startsWith("*")) s"%${n.substring(1)}"
      else n

    def suffix(n: String) =
      if (n.endsWith("*")) s"${n.dropRight(1)}%"
      else n

    val res = prefix(suffix(value))
    if (res == "%%") "%"
    else res
  }

}
