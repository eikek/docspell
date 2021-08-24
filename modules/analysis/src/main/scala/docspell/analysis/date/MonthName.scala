/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis.date

import docspell.common.Language

object MonthName {

  def getAll(lang: Language): List[List[String]] =
    merge(numbers, forLang(lang))

  private def merge(n0: List[List[String]], ns: List[List[String]]*): List[List[String]] =
    ns.foldLeft(n0) { (res, el) =>
      res.zip(el).map { case (a, b) => a ++ b }
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
      case Language.Spanish =>
        spanish
      case Language.Swedish =>
        swedish
      case Language.Norwegian =>
        norwegian
      case Language.Dutch =>
        dutch
      case Language.Czech =>
        czech
      case Language.Danish =>
        danish
      case Language.Portuguese =>
        portuguese
      case Language.Romanian =>
        romanian
      case Language.Finnish =>
        finnish
      case Language.Russian =>
        russian
      case Language.Latvian =>
        latvian
      case Language.Japanese =>
        japanese
      case Language.Hebrew =>
        hebrew
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

  private val spanish = List(
    List("ene", "enero"),
    List("feb", "febrero"),
    List("mar", "marzo"),
    List("abr", "abril"),
    List("may", "mayo"),
    List("jun"),
    List("jul"),
    List("ago", "agosto"),
    List("sep", "septiembre"),
    List("oct", "octubre"),
    List("nov", "noviembre"),
    List("dic", "diciembre")
  )

  private val swedish = List(
    List("jan", "januari"),
    List("febr", "februari"),
    List("mars"),
    List("april"),
    List("maj"),
    List("juni"),
    List("juli"),
    List("aug", "augusti"),
    List("sept", "september"),
    List("okt", "oktober"),
    List("nov", "november"),
    List("dec", "december")
  )
  private val norwegian = List(
    List("jan", "januar"),
    List("febr", "februar"),
    List("mars"),
    List("april"),
    List("mai"),
    List("juni"),
    List("juli"),
    List("aug", "august"),
    List("sept", "september"),
    List("okt", "oktober"),
    List("nov", "november"),
    List("des", "desember")
  )

  private val czech = List(
    List("led", "leden"),
    List("un", "ún", "únor", "unor"),
    List("brez", "březen", "brezen"),
    List("dub", "duben"),
    List("kvet", "květen"),
    List("cerv", "červen"),
    List("cerven", "červenec"),
    List("srp", "srpen"),
    List("zari", "září"),
    List("ríj", "rij", "říjen"),
    List("list", "listopad"),
    List("pros", "prosinec")
  )

  private val romanian = List(
    List("ian", "ianuarie"),
    List("feb", "februarie"),
    List("mar", "martie"),
    List("apr", "aprilie"),
    List("mai"),
    List("iunie"),
    List("iulie"),
    List("aug", "august"),
    List("sept", "septembrie"),
    List("oct", "octombrie"),
    List("noem", "nov", "noiembrie"),
    List("dec", "decembrie")
  )

  private val danish = List(
    List("jan", "januar"),
    List("febr", "februar"),
    List("marts"),
    List("april"),
    List("maj"),
    List("juni"),
    List("juli"),
    List("aug", "august"),
    List("sept", "september"),
    List("okt", "oktober"),
    List("nov", "november"),
    List("dec", "december")
  )

  private val portuguese = List(
    List("jan", "janeiro"),
    List("fev", "fevereiro"),
    List("março", "marco"),
    List("abril"),
    List("maio"),
    List("junho"),
    List("julho"),
    List("agosto"),
    List("set", "setembro"),
    List("out", "outubro"),
    List("nov", "novembro"),
    List("dez", "dezembro")
  )

  private val finnish = List(
    List("tammikuu"),
    List("helmikuu"),
    List("maaliskuu"),
    List("huhtikuu"),
    List("toukokuu"),
    List("kesäkuu"),
    List("heinäkuu"),
    List("elokuu"),
    List("syyskuu"),
    List("lokakuu"),
    List("marraskuu"),
    List("joulukuu")
  )

  private val russian = List(
    List("январь"),
    List("февраль"),
    List("март"),
    List("апрель"),
    List("май"),
    List("июнь"),
    List("июль"),
    List("август"),
    List("сентябрь"),
    List("октябрь"),
    List("ноябрь"),
    List("декабрь")
  )

  private val dutch = List(
    List("jan", "januari"),
    List("feb", "februari"),
    List("maart"),
    List("apr", "april"),
    List("mei"),
    List("juni"),
    List("juli"),
    List("aug", "augustus"),
    List("sept", "september"),
    List("okt", "oct", "oktober"),
    List("nov", "november"),
    List("dec", "december")
  )

  private val latvian = List(
    List("janvāris", "janv."),
    List("februāris", "febr."),
    List("marts"),
    List("aprīlis", "apr."),
    List("maijs"),
    List("jūnijs", "jūn."),
    List("jūlijs", "jūl."),
    List("augusts", "aug."),
    List("septembris", "sept."),
    List("oktobris", "okt."),
    List("novembris", "nov."),
    List("decembris", "dec.")
  )

  private val japanese = List(
    List("1", "一"),
    List("2", "二"),
    List("3", "三"),
    List("4", "四"),
    List("5", "五"),
    List("6", "六"),
    List("7", "七"),
    List("8", "八"),
    List("9", "九"),
    List("10", "十"),
    List("11", "十一"),
    List("12", "十二")
  )

  private val hebrew = List(
    List("1", "ינואר"),
    List("2", "פברואר"),
    List("3", "מרץ"),
    List("4", "אפריל"),
    List("5", "מאי"),
    List("6", "יוני"),
    List("7", "יולי"),
    List("8", "אוגוסט"),
    List("9", "ספטמבר"),
    List("10", "אוקטובר"),
    List("11", "נובמבר"),
    List("12", "דצמבר")
  )
}
