/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import docspell.common.syntax.all._

import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the classify-item task.
  *
  * This task is run periodically and learns from existing documents to create a model for
  * predicting tags of new documents. The user must give a tag category as a subset of
  * possible tags..
  */
case class LearnClassifierArgs(
    collectiveId: CollectiveId
) extends TaskArguments {

  def makeSubject: String =
    "Learn tags"
}

object LearnClassifierArgs {

  val taskName = Ident.unsafe("learn-classifier")

  implicit val jsonEncoder: Encoder[LearnClassifierArgs] =
    deriveEncoder[LearnClassifierArgs]
  implicit val jsonDecoder: Decoder[LearnClassifierArgs] =
    deriveDecoder[LearnClassifierArgs]

  def parse(str: String): Either[Throwable, LearnClassifierArgs] =
    str.parseJsonAs[LearnClassifierArgs]
}
