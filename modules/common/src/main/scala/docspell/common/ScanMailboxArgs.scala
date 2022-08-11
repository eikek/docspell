/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import docspell.common.syntax.all._

import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the poll-mailbox task.
  *
  * This tasks queries user mailboxes and pushes found mails into docspell for processing.
  *
  * If the structure changes, there must be some database migration to update or remove
  * the json data of the corresponding task.
  */
case class ScanMailboxArgs(
    // the docspell user account
    account: AccountInfo,
    // the configured imap connection
    imapConnection: Ident,
    // scan folders recursively
    scanRecursively: Option[Boolean],
    // what folders to search
    folders: List[String],
    // only select mails received since then
    receivedSince: Option[Duration],
    // move submitted mails to another folder
    targetFolder: Option[String],
    // delete the after submitting (only if targetFolder is None)
    deleteMail: Boolean,
    // set the direction when submitting
    direction: Option[Direction],
    // set a folder for items
    itemFolder: Option[Ident],
    // set a filter for files when importing archives
    fileFilter: Option[Glob],
    // set a list of tags to apply to new item
    tags: Option[List[String]],
    // a glob filter for the mail subject
    subjectFilter: Option[Glob],
    // the language for extraction and analysis
    language: Option[Language],
    // apply additional filter to all mails or only imported
    postHandleAll: Option[Boolean],
    // Exclude the mail body when importing
    attachmentsOnly: Option[Boolean]
) extends TaskArguments

object ScanMailboxArgs {

  val taskName = Ident.unsafe("scan-mailbox")

  implicit val jsonEncoder: Encoder[ScanMailboxArgs] =
    deriveEncoder[ScanMailboxArgs]
  implicit val jsonDecoder: Decoder[ScanMailboxArgs] =
    deriveDecoder[ScanMailboxArgs]

  def parse(str: String): Either[Throwable, ScanMailboxArgs] =
    str.parseJsonAs[ScanMailboxArgs]
}
