/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.learn

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.io.file.Files
import fs2.io.file.Path

import docspell.analysis.classifier.{ClassifierModel, TextClassifier}
import docspell.common._
import docspell.common.util.File
import docspell.logging.Logger
import docspell.store.Store
import docspell.store.records.RClassifierModel

object Classify {

  def apply[F[_]: Async](
      logger: Logger[F],
      workingDir: Path,
      store: Store[F],
      classifier: TextClassifier[F],
      coll: CollectiveId,
      text: String
  )(cname: ClassifierName): F[Option[String]] =
    (for {
      _ <- OptionT.liftF(logger.info(s"Guessing label for ${cname.name} …"))
      model <- OptionT(store.transact(RClassifierModel.findByName(coll, cname.name)))
        .flatTapNone(logger.debug("No classifier model found."))
      modelData = store.fileRepo.getBytes(model.fileId)
      cls <- OptionT(File.withTempDir(workingDir, "classify").use { dir =>
        val modelFile = dir.resolve("model.ser.gz")
        modelData
          .through(Files[F].writeAll(modelFile))
          .compile
          .drain
          .flatMap(_ => classifier.classify(logger, ClassifierModel(modelFile), text))
      }).filter(_ != LearnClassifierTask.noClass)
        .flatTapNone(logger.debug("Guessed: <none>"))
      _ <- OptionT.liftF(logger.debug(s"Guessed: $cls"))
    } yield cls).value

}
