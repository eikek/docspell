/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis.classifier

import cats.data.Kleisli
import fs2.Stream

import docspell.analysis.classifier.TextClassifier.Data
import docspell.common._

trait TextClassifier[F[_]] {

  def trainClassifier[A](logger: Logger[F], data: Stream[F, Data])(
      handler: TextClassifier.Handler[F, A]
  ): F[A]

  def classify(logger: Logger[F], model: ClassifierModel, text: String): F[Option[String]]

}

object TextClassifier {

  type Handler[F[_], A] = Kleisli[F, ClassifierModel, A]

  case class Data(cls: String, ref: String, text: String)

}
