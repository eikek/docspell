/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._
import io.circe._
import io.circe.generic.semiauto._

/** Arguments for the task that finds all pdf files that have not been converted and
  * submits for each a job that will convert the file using ocrmypdf.
  *
  * If the `collective` argument is present, then this task and the ones that are
  * submitted by this task run in the realm of the collective (and only their files are
  * considered). If it is empty, it is a system task and all files are considered.
  *
  * @deprecated
  *   replaced with same using `CollectiveId`
  */
case class ConvertAllPdfArgs(collective: Option[Ident])

object ConvertAllPdfArgs {

  val taskName = Ident.unsafe("submit-pdf-migration-tasks")

  implicit val jsonDecoder: Decoder[ConvertAllPdfArgs] =
    deriveDecoder[ConvertAllPdfArgs]

  implicit val jsonEncoder: Encoder[ConvertAllPdfArgs] =
    deriveEncoder[ConvertAllPdfArgs]
}
