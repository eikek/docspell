package docspell.joex.scanmailbox

import cats.implicits._
import cats.effect._
import emil._
//import emil.javamail.syntax._

import docspell.common._
import docspell.store.records._
import docspell.joex.scheduler.{Context, Task}

object ScanMailboxTask {
  val maxItems: Long = 7
  type Args = ScanMailboxArgs

  def apply[F[_]: Sync](emil: Emil[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(
          s"Start importing mails for user ${ctx.args.account.user.id}"
        )
        mailCfg <- getMailSettings(ctx)
        folders  = ctx.args.folders.mkString(", ")
        userId   = ctx.args.account.user
        imapConn = ctx.args.imapConnection
        _ <- ctx.logger.info(
          s"Reading mails for user ${userId.id} from ${imapConn.id}/${folders}"
        )
        _ <- importMails(mailCfg, emil, ctx)
      } yield ()
    }

  def onCancel[F[_]: Sync]: Task[F, ScanMailboxArgs, Unit] =
    Task.log(_.warn("Cancelling scan-mailbox task"))

  def getMailSettings[F[_]: Sync](ctx: Context[F, Args]): F[RUserImap] =
    ctx.store
      .transact(RUserImap.getByName(ctx.args.account, ctx.args.imapConnection))
      .flatMap {
        case Some(c) => c.pure[F]
        case None =>
          Sync[F].raiseError(
            new Exception(
              s"No imap configuration found for: ${ctx.args.imapConnection.id}"
            )
          )
      }

  def importMails[F[_]: Sync](
      cfg: RUserImap,
      emil: Emil[F],
      ctx: Context[F, Args]
  ): F[Unit] =
    Sync[F].delay(println(s"$emil $ctx $cfg"))
}
