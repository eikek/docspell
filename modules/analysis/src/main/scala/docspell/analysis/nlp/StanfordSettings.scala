package docspell.analysis.nlp

import java.nio.file.Path

import docspell.common._

/** Settings for configuring the stanford NER pipeline.
  *
  * The language is mandatory, only the provided ones are supported.
  * The `highRecall` only applies for non-English languages. For
  * non-English languages the english classifier is run as second
  * classifier and if `highRecall` is true, then it will be used to
  * tag untagged tokens. This may lead to a lot of false positives,
  * but since English is omnipresent in other languages, too it
  * depends on the use case for whether this is useful or not.
  *
  * The `regexNer` allows to specify a text file as described here:
  * https://nlp.stanford.edu/software/regexner.html. This will be used
  * as a last step to tag untagged tokens using the provided list of
  * regexps.
  */
case class StanfordSettings(lang: Language, highRecall: Boolean, regexNer: Option[Path])
