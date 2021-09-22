/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.nlp

import java.net.URL
import java.util.concurrent.atomic.AtomicReference
import java.util.zip.GZIPInputStream

import scala.jdk.CollectionConverters._
import scala.util.Using

import docspell.common.Language.NLPLanguage
import docspell.common._

import edu.stanford.nlp.ie.AbstractSequenceClassifier
import edu.stanford.nlp.ie.crf.CRFClassifier
import edu.stanford.nlp.ling.{CoreAnnotations, CoreLabel}
import org.log4s.getLogger

/** This is only using the CRFClassifier without building an analysis pipeline. The
  * ner-classifier cannot use results from POS-tagging etc. and is therefore not as good
  * as the [[StanfordNerAnnotator]]. But it uses less memory, while still being not bad.
  */
object BasicCRFAnnotator {
  private[this] val logger = getLogger

  // assert correct resource names
  List(Language.French, Language.German, Language.English).foreach(classifierResource)

  type Annotator = AbstractSequenceClassifier[CoreLabel]

  def nerAnnotate(nerClassifier: Annotator)(text: String): Vector[NerLabel] =
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

  def makeAnnotator(lang: NLPLanguage): Annotator = {
    logger.info(s"Creating ${lang.name} Stanford NLP NER-only classifier...")
    val ner = classifierResource(lang)
    Using(new GZIPInputStream(ner.openStream())) { in =>
      CRFClassifier.getClassifier(in).asInstanceOf[Annotator]
    }.fold(throw _, identity)
  }

  private def classifierResource(lang: NLPLanguage): URL = {
    def check(name: String): URL =
      Option(getClass.getResource(name)) match {
        case None =>
          sys.error(s"NER model resource '$name' not found for language ${lang.name}")
        case Some(url) => url
      }

    check(lang match {
      case Language.French =>
        "/edu/stanford/nlp/models/ner/french-wikiner-4class.crf.ser.gz"
      case Language.German =>
        "/edu/stanford/nlp/models/ner/german.distsim.crf.ser.gz"
      case Language.English =>
        "/edu/stanford/nlp/models/ner/english.conll.4class.distsim.crf.ser.gz"
    })
  }

  final class Cache {
    private[this] lazy val germanNerClassifier = makeAnnotator(Language.German)
    private[this] lazy val englishNerClassifier = makeAnnotator(Language.English)
    private[this] lazy val frenchNerClassifier = makeAnnotator(Language.French)

    def forLang(language: NLPLanguage): Annotator =
      language match {
        case Language.French  => frenchNerClassifier
        case Language.German  => germanNerClassifier
        case Language.English => englishNerClassifier
      }
  }

  object Cache {

    private[this] val cacheRef = new AtomicReference[Cache](new Cache)

    def getAnnotator(language: NLPLanguage): Annotator =
      cacheRef.get().forLang(language)

    def clearCache(): Unit =
      cacheRef.set(new Cache)
  }
}
