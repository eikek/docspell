/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.addon

import docspell.addons.AddonResult
import docspell.scheduler.JobTaskResultEncoder

import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

case class Result(addonResult: AddonResult, addons: List[String])

object Result {
  val empty: Result =
    Result(AddonResult.empty, Nil)

  implicit val jsonEncoder: Encoder[Result] =
    deriveEncoder

  implicit val jobTaskResultEncoder: JobTaskResultEncoder[Result] =
    JobTaskResultEncoder.fromJson[Result].withMessage { result =>
      result.addonResult match {
        case AddonResult.Success(_) =>
          s"Executed ${result.addons.size} addon(s) successfully."

        case AddonResult.ExecutionError(rc) =>
          s"Addon execution finished with non-zero return code: $rc"

        case AddonResult.ExecutionFailed(ex) =>
          s"Addon execution failed: ${ex.getMessage}"

        case AddonResult.DecodingError(msg) =>
          s"Addon output failed to read: $msg"
      }
    }
}
