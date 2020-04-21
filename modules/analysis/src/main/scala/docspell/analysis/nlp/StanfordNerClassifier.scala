package docspell.analysis.nlp

import java.util.{Properties => JProps}

import scala.jdk.CollectionConverters._

import docspell.common._

import edu.stanford.nlp.pipeline.{CoreDocument, StanfordCoreNLP}
import org.log4s.getLogger

object StanfordNerClassifier {
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
    val doc = new CoreDocument(text)
    nerClassifier.annotate(doc)

    doc.tokens().asScala.collect(Function.unlift(LabelConverter.toNerLabel)).toVector
  }

  private def makeClassifier(lang: Language): StanfordCoreNLP = {
    logger.info(s"Creating ${lang.name} Stanford NLP NER classifier...")
    new StanfordCoreNLP(classifierProperties(lang))
  }

  private def classifierProperties(lang: Language): JProps =
    lang match {
      case Language.German =>
        Properties.nerGerman(None, false)
      case Language.English =>
        Properties.nerEnglish(None)
      case Language.French =>
        Properties.nerFrench(None, false)
    }
}
