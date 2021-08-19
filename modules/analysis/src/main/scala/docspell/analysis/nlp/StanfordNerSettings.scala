/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis.nlp

import fs2.io.file.Path

import docspell.analysis.NlpSettings
import docspell.common.Language.NLPLanguage

sealed trait StanfordNerSettings

object StanfordNerSettings {

  /** Settings for configuring the stanford NER pipeline.
    *
    * The language is mandatory, only the provided ones are supported. The `highRecall`
    * only applies for non-English languages. For non-English languages the english
    * classifier is run as second classifier and if `highRecall` is true, then it will be
    * used to tag untagged tokens. This may lead to a lot of false positives, but since
    * English is omnipresent in other languages, too it depends on the use case for
    * whether this is useful or not.
    *
    * The `regexNer` allows to specify a text file as described here:
    * https://nlp.stanford.edu/software/regexner.html. This will be used as a last step to
    * tag untagged tokens using the provided list of regexps.
    */
  case class Full(
      lang: NLPLanguage,
      highRecall: Boolean,
      regexNer: Option[Path]
  ) extends StanfordNerSettings

  /** Not all languages are supported with predefined statistical models. This allows to
    * provide regexps only.
    */
  case class RegexOnly(regexNerFile: Path) extends StanfordNerSettings

  def fromNlpSettings(ns: NlpSettings): Option[StanfordNerSettings] =
    NLPLanguage.all
      .find(nl => nl == ns.lang)
      .map(nl => Full(nl, ns.highRecall, ns.regexNer))
      .orElse(ns.regexNer.map(nrf => RegexOnly(nrf)))
}
