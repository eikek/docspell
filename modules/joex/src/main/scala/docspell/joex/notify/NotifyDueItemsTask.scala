/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.notify

import cats.data.{NonEmptyList => Nel, OptionT}
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OItemSearch.{Batch, ListItem, Query}
import docspell.common._
import docspell.joex.mail.EmilHeader
import docspell.joex.scheduler.{Context, Task}
import docspell.query.Date
import docspell.query.ItemQuery._
import docspell.query.ItemQueryDsl._
import docspell.store.queries.QItem
import docspell.store.records._

import emil._
import emil.builder._
import emil.javamail.syntax._
import emil.markdown._

object NotifyDueItemsTask {
  val maxItems: Int = 7
  type Args = NotifyDueItemsArgs

  def apply[F[_]: Sync](cfg: MailSendConfig, emil: Emil[F]): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _       <- ctx.logger.info("Getting mail configuration")
        mailCfg <- getMailSettings(ctx)
        _ <- ctx.logger.info(
          s"Searching for items due in ${ctx.args.remindDays} days…."
        )
        _ <- createMail(cfg, mailCfg, ctx)
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

  def onCancel[F[_]]: Task[F, NotifyDueItemsArgs, Unit] =
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
      sendCfg: MailSendConfig,
      cfg: RUserEmail,
      ctx: Context[F, Args]
  ): OptionT[F, Mail[F]] =
    for {
      items <- OptionT.liftF(findItems(ctx)).filter(_.nonEmpty)
      mail  <- OptionT.liftF(makeMail(sendCfg, cfg, ctx.args, items))
    } yield mail

  def findItems[F[_]: Sync](ctx: Context[F, Args]): F[Vector[ListItem]] =
    for {
      now <- Timestamp.current[F]
      rightDate = Date((now + Duration.days(ctx.args.remindDays.toLong)).toMillis)
      q =
        Query
          .all(ctx.args.account)
          .withOrder(orderAsc = _.dueDate)
          .withFix(_.copy(query = Expr.ValidItemStates.some))
          .withCond(_ =>
            Query.QueryExpr(
              Attr.DueDate <= rightDate &&?
                ctx.args.daysBack.map(back =>
                  Attr.DueDate >= Date((now - Duration.days(back.toLong)).toMillis)
                ) &&?
                Nel
                  .fromList(ctx.args.tagsInclude)
                  .map(ids => Q.tagIdsEq(ids.map(_.id))) &&?
                Nel
                  .fromList(ctx.args.tagsExclude)
                  .map(ids => Q.tagIdsIn(ids.map(_.id)).negate)
            )
          )
      res <-
        ctx.store
          .transact(
            QItem
              .findItems(q, now.toUtcDate, 0, Batch.limit(maxItems))
              .take(maxItems.toLong)
          )
          .compile
          .toVector
    } yield res

  def makeMail[F[_]: Sync](
      sendCfg: MailSendConfig,
      cfg: RUserEmail,
      args: Args,
      items: Vector[ListItem]
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
        XMailer.emil,
        Subject("[Docspell] Next due items"),
        EmilHeader.listId(sendCfg.listId),
        MarkdownBody[F](md).withConfig(
          MarkdownConfig("body { font-size: 10pt; font-family: sans-serif; }")
        )
      )
    }
}
