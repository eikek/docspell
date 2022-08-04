/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OMail._
import docspell.common._
import docspell.store._
import docspell.store.queries.QMails
import docspell.store.records._
import docspell.store.syntax.MimeTypes._

import emil._

trait OMail[F[_]] {

  def getSmtpSettings(userId: Ident, nameQ: Option[String]): F[Vector[RUserEmail]]

  def findSmtpSettings(userId: Ident, name: Ident): OptionT[F, RUserEmail]

  def createSmtpSettings(userId: Ident, data: SmtpSettings): F[AddResult]

  def updateSmtpSettings(userId: Ident, name: Ident, data: OMail.SmtpSettings): F[Int]

  def deleteSmtpSettings(userId: Ident, name: Ident): F[Int]

  def getImapSettings(userId: Ident, nameQ: Option[String]): F[Vector[RUserImap]]

  def findImapSettings(userId: Ident, name: Ident): OptionT[F, RUserImap]

  def createImapSettings(userId: Ident, data: ImapSettings): F[AddResult]

  def updateImapSettings(userId: Ident, name: Ident, data: OMail.ImapSettings): F[Int]

  def deleteImapSettings(userId: Ident, name: Ident): F[Int]

  def sendMail(
      userId: Ident,
      collectiveId: CollectiveId,
      name: Ident,
      m: ItemMail
  ): F[SendResult]

  def getSentMailsForItem(collectiveId: CollectiveId, itemId: Ident): F[Vector[Sent]]

  def getSentMail(collectiveId: CollectiveId, mailId: Ident): OptionT[F, Sent]

  def deleteSentMail(collectiveId: CollectiveId, mailId: Ident): F[Int]
}

object OMail {
  sealed trait SendResult

  object SendResult {

    /** Mail was successfully sent and stored to db. */
    case class Success(id: Ident) extends SendResult

    /** There was a failure sending the mail. The mail is then not saved to db. */
    case class SendFailure(ex: Throwable) extends SendResult

    /** The mail was successfully sent, but storing to db failed. */
    case class StoreFailure(ex: Throwable) extends SendResult

    /** Something could not be found required for sending (mail configs, items etc). */
    case object NotFound extends SendResult
  }

  case class Sent(
      id: Ident,
      senderLogin: Ident,
      connectionName: Ident,
      recipients: List[MailAddress],
      subject: String,
      body: String,
      created: Timestamp
  )

  object Sent {

    def create(r: RSentMail, login: Ident): Sent =
      Sent(r.id, login, r.connName, r.recipients, r.subject, r.body, r.created)
  }

  case class ItemMail(
      item: Ident,
      subject: String,
      recipients: List[MailAddress],
      cc: List[MailAddress],
      bcc: List[MailAddress],
      body: String,
      attach: AttachSelection
  )

  sealed trait AttachSelection {
    def filter(v: Vector[(RAttachment, RFileMeta)]): Vector[(RAttachment, RFileMeta)]
  }
  object AttachSelection {
    case object All extends AttachSelection {
      def filter(v: Vector[(RAttachment, RFileMeta)]): Vector[(RAttachment, RFileMeta)] =
        v
    }
    case class Selected(ids: List[Ident]) extends AttachSelection {
      def filter(
          v: Vector[(RAttachment, RFileMeta)]
      ): Vector[(RAttachment, RFileMeta)] = {
        val set = ids.toSet
        v.filter(set contains _._1.id)
      }
    }
  }

  case class SmtpSettings(
      name: Ident,
      smtpHost: String,
      smtpPort: Option[Int],
      smtpUser: Option[String],
      smtpPassword: Option[Password],
      smtpSsl: SSLType,
      smtpCertCheck: Boolean,
      mailFrom: MailAddress,
      mailReplyTo: Option[MailAddress]
  ) {

    def toRecord(userId: Ident) =
      RUserEmail.fromUser(
        userId,
        name,
        smtpHost,
        smtpPort,
        smtpUser,
        smtpPassword,
        smtpSsl,
        smtpCertCheck,
        mailFrom,
        mailReplyTo
      )
  }

  case class ImapSettings(
      name: Ident,
      imapHost: String,
      imapPort: Option[Int],
      imapUser: Option[String],
      imapPassword: Option[Password],
      imapSsl: SSLType,
      imapCertCheck: Boolean,
      imapOAuth2: Boolean
  ) {

    def toRecord(userId: Ident) =
      RUserImap.fromUser(
        userId,
        name,
        imapHost,
        imapPort,
        imapUser,
        imapPassword,
        imapSsl,
        imapCertCheck,
        imapOAuth2
      )
  }

  def apply[F[_]: Async](store: Store[F], emil: Emil[F]): Resource[F, OMail[F]] =
    Resource.pure[F, OMail[F]](new OMail[F] {
      def getSmtpSettings(
          userId: Ident,
          nameQ: Option[String]
      ): F[Vector[RUserEmail]] =
        store.transact(RUserEmail.findByAccount(userId, nameQ))

      def findSmtpSettings(userId: Ident, name: Ident): OptionT[F, RUserEmail] =
        OptionT(store.transact(RUserEmail.getByName(userId, name)))

      def createSmtpSettings(userId: Ident, s: SmtpSettings): F[AddResult] =
        (for {
          ru <- OptionT(store.transact(s.toRecord(userId).value))
          ins = RUserEmail.insert(ru)
          exists = RUserEmail.exists(ru.uid, ru.name)
          res <- OptionT.liftF(store.add(ins, exists))
        } yield res).getOrElse(AddResult.Failure(new Exception("User not found")))

      def updateSmtpSettings(
          userId: Ident,
          name: Ident,
          data: SmtpSettings
      ): F[Int] = {
        val op = for {
          um <- OptionT(RUserEmail.getByName(userId, name))
          ru <- data.toRecord(userId)
          n <- OptionT.liftF(RUserEmail.update(um.id, ru))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }

      def deleteSmtpSettings(userId: Ident, name: Ident): F[Int] =
        store.transact(RUserEmail.delete(userId, name))

      def getImapSettings(userId: Ident, nameQ: Option[String]): F[Vector[RUserImap]] =
        store.transact(RUserImap.findByAccount(userId, nameQ))

      def findImapSettings(userId: Ident, name: Ident): OptionT[F, RUserImap] =
        OptionT(store.transact(RUserImap.getByName(userId, name)))

      def createImapSettings(userId: Ident, data: ImapSettings): F[AddResult] =
        (for {
          ru <- OptionT(store.transact(data.toRecord(userId).value))
          ins = RUserImap.insert(ru)
          exists = RUserImap.exists(ru.uid, ru.name)
          res <- OptionT.liftF(store.add(ins, exists))
        } yield res).getOrElse(AddResult.Failure(new Exception("User not found")))

      def updateImapSettings(
          userId: Ident,
          name: Ident,
          data: OMail.ImapSettings
      ): F[Int] = {
        val op = for {
          um <- OptionT(RUserImap.getByName(userId, name))
          ru <- data.toRecord(userId)
          n <- OptionT.liftF(RUserImap.update(um.id, ru))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }

      def deleteImapSettings(userId: Ident, name: Ident): F[Int] =
        store.transact(RUserImap.delete(userId, name))

      def sendMail(
          userId: Ident,
          collectiveId: CollectiveId,
          name: Ident,
          m: ItemMail
      ): F[SendResult] = {

        val getSmtpSettings: OptionT[F, RUserEmail] =
          OptionT(store.transact(RUserEmail.getByName(userId, name)))

        def createMail(sett: RUserEmail): OptionT[F, Mail[F]] = {
          import _root_.emil.builder._

          for {
            _ <- OptionT.liftF(store.transact(RItem.existsById(m.item))).filter(identity)
            ras <- OptionT.liftF(
              store.transact(
                RAttachment.findByItemAndCollectiveWithMeta(m.item, collectiveId)
              )
            )
          } yield {
            val addAttach = m.attach.filter(ras).map { a =>
              Attach[F](
                store.fileRepo.getBytes(a._2.id)
              ).withFilename(a._1.name)
                .withLength(a._2.length.bytes)
                .withMimeType(a._2.mimetype.toEmil)
            }
            val fields: Seq[Trans[F]] = Seq(
              From(sett.mailFrom),
              Tos(m.recipients),
              Ccs(m.cc),
              Bccs(m.bcc),
              XMailer.emil,
              Subject(m.subject),
              TextBody[F](m.body)
            )

            MailBuilder.fromSeq[F](fields).addAll(addAttach).build
          }
        }

        def sendMail(cfg: MailConfig, mail: Mail[F]): F[Either[SendResult, String]] =
          emil(cfg).send(mail).map(_.head).attempt.map(_.left.map(SendResult.SendFailure))

        def storeMail(msgId: String, cfg: RUserEmail): F[Either[SendResult, Ident]] = {
          val save = for {
            data <- RSentMail.forItem(
              m.item,
              userId,
              msgId,
              cfg.mailFrom,
              name,
              m.subject,
              m.recipients,
              m.body
            )
            _ <- OptionT.liftF(RSentMail.insert(data._1))
            _ <- OptionT.liftF(RSentMailItem.insert(data._2))
          } yield data._1.id

          store.transact(save.value).attempt.map {
            case Right(Some(id)) => Right(id)
            case Right(None) =>
              Left(
                SendResult
                  .StoreFailure(new Exception(s"Could not find user to save mail."))
              )
            case Left(ex) => Left(SendResult.StoreFailure(ex))
          }
        }

        (for {
          mailCfg <- getSmtpSettings
          mail <- createMail(mailCfg)
          mid <- OptionT.liftF(sendMail(mailCfg.toMailConfig, mail))
          res <- mid.traverse(id => OptionT.liftF(storeMail(id, mailCfg)))
          conv = res.fold(identity, _.fold(identity, id => SendResult.Success(id)))
        } yield conv).getOrElse(SendResult.NotFound)
      }

      def getSentMailsForItem(
          collectiveId: CollectiveId,
          itemId: Ident
      ): F[Vector[Sent]] =
        store
          .transact(QMails.findMails(collectiveId, itemId))
          .map(_.map(t => Sent.create(t._1, t._2)))

      def getSentMail(collectiveId: CollectiveId, mailId: Ident): OptionT[F, Sent] =
        OptionT(store.transact(QMails.findMail(collectiveId, mailId))).map(t =>
          Sent.create(t._1, t._2)
        )

      def deleteSentMail(collectiveId: CollectiveId, mailId: Ident): F[Int] =
        store.transact(QMails.delete(collectiveId, mailId))
    })
}
