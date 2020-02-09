package docspell.text.contact

private[text] object Tld {

  def findTld(str: String): Option[String] =
    known.find(str.endsWith)

  def endsWithTld(str: String): Boolean =
    findTld(str).isDefined

  /**
    * Some selected TLDs.
    */
  private[this] val known = List(
    ".com",
    ".org",
    ".net",
    ".int",
    ".edu",
    ".gov",
    ".mil",
    ".ad",
    ".ae",
    ".al",
    ".am",
    ".ar",
    ".as",
    ".at",
    ".au",
    ".ax",
    ".ba",
    ".bd",
    ".be",
    ".bg",
    ".br",
    ".by",
    ".bz",
    ".ca",
    ".cc",
    ".ch",
    ".cn",
    ".co",
    ".cu",
    ".cx",
    ".cy",
    ".de",
    ".dk",
    ".dj",
    ".ee",
    ".eu",
    ".fi",
    ".fr",
    ".gr",
    ".hk",
    ".hr",
    ".hu",
    ".ie",
    ".il",
    ".io",
    ".is",
    ".ir",
    ".it",
    ".jp",
    ".li",
    ".lt",
    ".mt",
    ".no",
    ".nz",
    ".pl",
    ".pt",
    ".ru",
    ".rs",
    ".se",
    ".si",
    ".sk",
    ".th",
    ".ua",
    ".uk",
    ".us",
    ".ws"
  )

}
