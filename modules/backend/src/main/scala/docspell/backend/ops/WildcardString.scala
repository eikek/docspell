package docspell.backend.ops

final class WildcardString private (str: String) {

  def both: String =
    if (str.startsWith("\"") && str.endsWith("\"")) str.drop(1).dropRight(1)
    else if (str.startsWith("*") || str.endsWith("*")) str
    else s"*$str*"

}
object WildcardString {

  def apply(in: String): WildcardString =
    new WildcardString(in.trim)

}
