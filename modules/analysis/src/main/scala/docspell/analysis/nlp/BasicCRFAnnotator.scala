package docspell.analysis.nlp

import docspell.common._
import edu.stanford.nlp.ie.AbstractSequenceClassifier
import edu.stanford.nlp.ie.crf.CRFClassifier
import edu.stanford.nlp.ling.{CoreAnnotations, CoreLabel}
import org.log4s.getLogger

import java.net.URL
import java.util.zip.GZIPInputStream

import scala.jdk.CollectionConverters._
import scala.util.Using

/** This is only using the CRFClassifier without building an analysis
  * pipeline. The ner-classifier cannot use results from POS-tagging
  * etc. and is therefore not as good as the [[StanfordNerAnnotator]].
  * But it uses less memory, while still being not bad.
  */
object BasicCRFAnnotator {
  private[this] val logger = getLogger

  lazy val germanNerClassifier  = makeClassifier(Language.German)
  lazy val englishNerClassifier = makeClassifier(Language.English)
  lazy val frenchNerClassifier  = makeClassifier(Language.French)

  def nerAnnotate(lang: Language)(text: String): Vector[NerLabel] = {
    val nerClassifier = lang match {
      case Language.English => englishNerClassifier
      case Language.German  => germanNerClassifier
      case Language.French  => frenchNerClassifier
    }
    nerClassifier
      .classify(text)
      .asScala
      .flatMap(a => a.asScala)
      .collect(Function.unlift { label =>
        val tag = label.get(classOf[CoreAnnotations.AnswerAnnotation])
        NerTag
          .fromString(Option(tag).getOrElse(""))
          .toOption
          .map(t => NerLabel(label.word(), t, label.beginPosition(), label.endPosition()))
      })
      .toVector
  }

  private def makeClassifier(lang: Language): AbstractSequenceClassifier[CoreLabel] = {
    logger.info(s"Creating ${lang.name} Stanford NLP NER-only classifier...")
    val ner = classifierResource(lang)
    Using(new GZIPInputStream(ner.openStream())) { in =>
      CRFClassifier.getClassifier(in).asInstanceOf[AbstractSequenceClassifier[CoreLabel]]
    }.fold(throw _, identity)
  }

  private def classifierResource(lang: Language): URL = {
    def check(u: URL): URL =
      if (u == null) sys.error(s"NER model url not found for language ${lang.name}")
      else u

    check(lang match {
      case Language.French =>
        getClass.getResource(
          "/edu/stanford/nlp/models/ner/french-wikiner-4class.crf.ser.gz"
        )
      case Language.German =>
        getClass.getResource(
          "/edu/stanford/nlp/models/ner/german.distsim.crf.ser.gz"
        )
      case Language.English =>
        getClass.getResource(
          "/edu/stanford/nlp/models/ner/english.conll.4class.distsim.crf.ser.gz"
        )
    })
  }
}
