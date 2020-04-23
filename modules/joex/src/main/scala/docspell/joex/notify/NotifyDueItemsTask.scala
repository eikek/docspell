package docspell.joex.hk

import cats.implicits._
import cats.effect._
import emil._
import emil.builder._
import emil.markdown._
import emil.javamail.syntax._

import docspell.common._
import docspell.store.records._
import docspell.store.queries.QItem
import docspell.joex.scheduler.{Context, Task}
import cats.data.OptionT
import docspell.joex.notify.MailContext
import docspell.joex.notify.MailTemplate

object NotifyDueItemsTask {
  val maxItems: Long = 7
  type Args = NotifyDueItemsArgs

  def apply[F[_]: Sync](emil: Emil[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _       <- ctx.logger.info("Getting mail configuration")
        mailCfg <- getMailSettings(ctx)
        _ <- ctx.logger.info(
          s"Searching for items due in ${ctx.args.remindDays} days…."
        )
        _ <- createMail(mailCfg, ctx)
          .semiflatMap { mail =>
            for {
              _   <- ctx.logger.info(s"Sending notification mail to ${ctx.args.recipients}")
              res <- emil(mailCfg.toMailConfig).send(mail).map(_.head)
              _   <- ctx.logger.info(s"Sent mail with id: $res")
            } yield ()
          }
          .getOrElseF(ctx.logger.info("No items found"))
      } yield ()
    }

  def onCancel[F[_]: Sync]: Task[F, NotifyDueItemsArgs, Unit] =
    Task.log(_.warn("Cancelling notify-due-items task"))

  def getMailSettings[F[_]: Sync](ctx: Context[F, Args]): F[RUserEmail] =
    ctx.store
      .transact(RUserEmail.getByName(ctx.args.account, ctx.args.smtpConnection))
      .flatMap {
        case Some(c) => c.pure[F]
        case None =>
          Sync[F].raiseError(
            new Exception(
              s"No smtp configuration found for: ${ctx.args.smtpConnection.id}"
            )
          )
      }

  def createMail[F[_]: Sync](
      cfg: RUserEmail,
      ctx: Context[F, Args]
  ): OptionT[F, Mail[F]] =
    for {
      items <- OptionT.liftF(findItems(ctx)).filter(_.nonEmpty)
      mail  <- OptionT.liftF(makeMail(cfg, ctx.args, items))
    } yield mail

  def findItems[F[_]: Sync](ctx: Context[F, Args]): F[Vector[QItem.ListItem]] =
    for {
      now <- Timestamp.current[F]
      q = QItem.Query
        .empty(ctx.args.account.collective)
        .copy(
          states = ItemState.validStates,
          tagsInclude = ctx.args.tagsInclude,
          tagsExclude = ctx.args.tagsExclude,
          dueDateFrom = ctx.args.daysBack.map(back => now - Duration.days(back.toLong)),
          dueDateTo = Some(now + Duration.days(ctx.args.remindDays.toLong)),
          orderAsc = Some(_.dueDate)
        )
      res <- ctx.store.transact(QItem.findItems(q).take(maxItems)).compile.toVector
    } yield res

  def makeMail[F[_]: Sync](
      cfg: RUserEmail,
      args: Args,
      items: Vector[QItem.ListItem]
  ): F[Mail[F]] =
    Timestamp.current[F].map { now =>
      val templateCtx =
        MailContext.from(items, maxItems.toInt, args.account, args.itemDetailUrl, now)
      val md = MailTemplate.render(templateCtx)
      val recp = args.recipients
        .map(MailAddress.parse)
        .map {
          case Right(ma) => ma
          case Left(err) =>
            throw new Exception(s"Unable to parse recipient address: $err")
        }
      MailBuilder.build(
        From(cfg.mailFrom),
        Tos(recp),
        Subject("Next due items"),
        MarkdownBody[F](md)
      )
    }
}
