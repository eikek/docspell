/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import io.circe._
import io.circe.generic.semiauto._

/** Arguments for the task that finds all pdf files that have not been converted and
  * submits for each a job that will convert the file using ocrmypdf.
  *
  * If the `collective` argument is present, then this task and the ones that are
  * submitted by this task run in the realm of the collective (and only their files are
  * considered). If it is empty, it is a system task and all files are considered.
  */
case class ConvertAllPdfArgs(collective: Option[CollectiveId]) extends TaskArguments

object ConvertAllPdfArgs {

  val taskName = Ident.unsafe("submit-pdf-migration-tasks")

  implicit val jsonDecoder: Decoder[ConvertAllPdfArgs] =
    deriveDecoder[ConvertAllPdfArgs]

  implicit val jsonEncoder: Encoder[ConvertAllPdfArgs] =
    deriveEncoder[ConvertAllPdfArgs]
}
