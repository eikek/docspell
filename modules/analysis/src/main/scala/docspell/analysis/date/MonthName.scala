package docspell.analysis.date

import docspell.common.Language

object MonthName {

  def getAll(lang: Language): List[List[String]] =
    merge(numbers, forLang(lang))

  private def merge(n0: List[List[String]], ns: List[List[String]]*): List[List[String]] =
    ns.foldLeft(n0) { (res, el) =>
      res.zip(el).map({ case (a, b) => a ++ b })
    }

  private def forLang(lang: Language): List[List[String]] =
    lang match {
      case Language.English =>
        english
      case Language.German =>
        german
      case Language.French =>
        french
      case Language.Italian =>
        italian
    }

  private val numbers = List(
    List("01"),
    List("02"),
    List("03"),
    List("04"),
    List("05"),
    List("06"),
    List("07"),
    List("08"),
    List("09"),
    List("10"),
    List("11"),
    List("12")
  )

  private val english = List(
    List("jan", "january"),
    List("feb", "february"),
    List("mar", "march"),
    List("apr", "april"),
    List("may"),
    List("jun", "june"),
    List("jul", "july"),
    List("aug", "august"),
    List("sept", "september"),
    List("oct", "october"),
    List("nov", "november"),
    List("dec", "december")
  )

  private val german = List(
    List("jan", "januar"),
    List("feb", "februar"),
    List("märz"),
    List("apr", "april"),
    List("mai"),
    List("juni"),
    List("juli"),
    List("aug", "august"),
    List("sept", "september"),
    List("okt", "oktober"),
    List("nov", "november"),
    List("dez", "dezember")
  )

  private val french = List(
    List("janv", "janvier"),
    List("févr", "fevr", "février", "fevrier"),
    List("mars"),
    List("avril"),
    List("mai"),
    List("juin"),
    List("juil", "juillet"),
    List("aout", "août"),
    List("sept", "septembre"),
    List("oct", "octobre"),
    List("nov", "novembre"),
    List("dec", "déc", "décembre", "decembre")
  )

  private val italian = List(
    List("genn", "gennaio"),
    List("febbr", "febbraio"),
    List("mar", "marzo"),
    List("apr", "aprile"),
    List("magg", "maggio"),
    List("giugno"),
    List("luglio"),
    List("ag", "agosto"),
    List("sett", "settembre"),
    List("ott", "ottobre"),
    List("nov", "novembre"),
    List("dic", "dicembre")
  )
}
