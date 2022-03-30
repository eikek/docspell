/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.multiupload

import cats.Monoid

import docspell.scheduler.JobTaskResultEncoder

import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

case class Result(submittedFiles: Int, extractedZips: Int)

object Result {
  val empty: Result = Result(0, 0)
  def notExtracted: Result = Result(1, 0)

  implicit val resultMonoid: Monoid[Result] =
    Monoid.instance(
      empty,
      (a, b) =>
        Result(a.submittedFiles + b.submittedFiles, a.extractedZips + b.extractedZips)
    )

  implicit val jsonEncoder: Encoder[Result] =
    deriveEncoder

  implicit val taskResultEncoder: JobTaskResultEncoder[Result] =
    JobTaskResultEncoder.fromJson[Result].withMessage { result =>
      s"Submitted ${result.submittedFiles} files, extracted ${result.extractedZips} zip files."
    }
}
