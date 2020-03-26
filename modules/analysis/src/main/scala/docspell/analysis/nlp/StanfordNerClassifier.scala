package docspell.analysis.nlp

import java.net.URL
import java.util.zip.GZIPInputStream

import edu.stanford.nlp.ie.AbstractSequenceClassifier
import edu.stanford.nlp.ie.crf.CRFClassifier
import edu.stanford.nlp.ling.{CoreAnnotations, CoreLabel}
import org.log4s.getLogger

import docspell.common._

import scala.util.Using
import scala.jdk.CollectionConverters._

object StanfordNerClassifier {
  private[this] val logger = getLogger

  lazy val germanNerClassifier  = makeClassifier(Language.German)
  lazy val englishNerClassifier = makeClassifier(Language.English)

  def nerAnnotate(lang: Language)(text: String): Vector[NerLabel] = {
    val nerClassifier = lang match {
      case Language.English => englishNerClassifier
      case Language.German  => germanNerClassifier
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
    logger.info(s"Creating ${lang.name} Stanford NLP NER classifier...")
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
      case Language.German =>
        getClass.getResource(
          "/edu/stanford/nlp/models/ner/german.conll.germeval2014.hgc_175m_600.crf.ser.gz"
        )
      case Language.English =>
        getClass.getResource(
          "/edu/stanford/nlp/models/ner/english.all.3class.distsim.crf.ser.gz"
        )
    })
  }
}
