/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.download

import docspell.scheduler.JobTaskResultEncoder

import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

final case class Result(fileCount: Int) {}

object Result {
  implicit val jsonEncoder: Encoder[Result] =
    deriveEncoder

  implicit val jobTaskResultEncoder: JobTaskResultEncoder[Result] =
    JobTaskResultEncoder.fromJson[Result].withMessage { result =>
      s"Zipped ${result.fileCount} files."
    }
}
