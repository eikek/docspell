/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import io.circe.Json

final case class JobTaskResult(message: Option[String], json: Option[Json]) {

  def withMessage(m: String): JobTaskResult =
    copy(message = Some(m))

  def withJson(json: Json): JobTaskResult =
    copy(json = Some(json))
}

object JobTaskResult {

  val empty: JobTaskResult = JobTaskResult(None, None)

  def message(msg: String): JobTaskResult = JobTaskResult(Some(msg), None)

  def json(json: Json): JobTaskResult = JobTaskResult(None, Some(json))
}
