package docspell.common

import docspell.common.syntax.all._

import io.circe._
import io.circe.generic.semiauto._

/** Arguments to the poll-mailbox task.
  *
  * This tasks queries user mailboxes and pushes found mails into
  * docspell for processing.
  *
  * If the structure changes, there must be some database migration to
  * update or remove the json data of the corresponding task.
  */
case class ScanMailboxArgs(
    // the docspell user account
    account: AccountId,
    // the configured imap connection
    imapConnection: Ident,
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
    itemFolder: Option[Ident]
)

object ScanMailboxArgs {

  val taskName = Ident.unsafe("scan-mailbox")

  implicit val jsonEncoder: Encoder[ScanMailboxArgs] =
    deriveEncoder[ScanMailboxArgs]
  implicit val jsonDecoder: Decoder[ScanMailboxArgs] =
    deriveDecoder[ScanMailboxArgs]

  def parse(str: String): Either[Throwable, ScanMailboxArgs] =
    str.parseJsonAs[ScanMailboxArgs]
}
