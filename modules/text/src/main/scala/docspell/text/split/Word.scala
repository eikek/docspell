package docspell.text.split

case class Word(value: String, begin: Int, end: Int) {
  def isEmpty: Boolean = value.isEmpty
  def nonEmpty: Boolean = !isEmpty
  def length : Int = value.length

  def trimLeft(chars: Set[Char]): Word = {
    val v = value.dropWhile(chars.contains)
    if (v == value) this
    else Word(v, begin + length - v.length, end)
  }

  def trimRight(chars: Set[Char]): Word = {
    @annotation.tailrec
    def findIndex(n: Int = length - 1): Int =
      if (n < 0 || !chars.contains(value.charAt(n))) n
      else findIndex(n - 1)

    val index = findIndex()
    if (index == length - 1) this
    else if (index < 0) Word("", begin, begin + 1)
    else Word(value.substring(0, index + 1), begin, end - index)
  }

  def trim(chars: Set[Char]): Word =
    trimLeft(chars).trimRight(chars)

  def toLower: Word =
    copy(value = value.toLowerCase)

}
