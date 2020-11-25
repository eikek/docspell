package docspell.backend.ops

final class WildcardString private (str: String) {

  def both: Option[String] =
    if (str.startsWith("\"") && str.endsWith("\"")) Some(str.drop(1).dropRight(1))
    else if (str.startsWith("*") || str.endsWith("*")) Some(str)
    else if (str.trim == "") None
    else Some(s"*$str*")

}
object WildcardString {

  def apply(in: String): WildcardString =
    new WildcardString(in.trim)

}
