/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.nlp

import scala.jdk.CollectionConverters._

import cats.effect._
import fs2.io.file.Path

import docspell.common._

import edu.stanford.nlp.pipeline.{CoreDocument, StanfordCoreNLP}

object StanfordNerAnnotator {
  private[this] val logger = docspell.logging.unsafeLogger

  /** Runs named entity recognition on the given `text`.
    *
    * This uses the classifier pipeline from stanford-nlp, see
    * https://nlp.stanford.edu/software/CRF-NER.html. Creating these classifiers is quite
    * expensive, it involves loading large model files. The classifiers are thread-safe
    * and so they are cached. The `cacheKey` defines the "slot" where classifiers are
    * stored and retrieved. If for a given `cacheKey` the `settings` change, a new
    * classifier must be created. It will then replace the previous one.
    */
  def nerAnnotate(nerClassifier: StanfordCoreNLP, text: String): Vector[NerLabel] = {
    val doc = new CoreDocument(text)
    nerClassifier.annotate(doc)
    doc.tokens().asScala.collect(Function.unlift(LabelConverter.toNerLabel)).toVector
  }

  def makePipeline(settings: StanfordNerSettings): StanfordCoreNLP =
    settings match {
      case s: StanfordNerSettings.Full =>
        logger.info(s"Creating ${s.lang.name} Stanford NLP NER classifier...")
        new StanfordCoreNLP(Properties.forSettings(settings))
      case StanfordNerSettings.RegexOnly(path) =>
        logger.info(s"Creating regexNer-only Stanford NLP NER classifier...")
        regexNerPipeline(path)
    }

  def regexNerPipeline(regexNerFile: Path): StanfordCoreNLP =
    new StanfordCoreNLP(Properties.regexNerOnly(regexNerFile))

  def clearPipelineCaches[F[_]: Sync]: F[Unit] =
    Sync[F].delay {
      // turns out that everything is cached in a static map
      StanfordCoreNLP.clearAnnotatorPool()
    }
}
