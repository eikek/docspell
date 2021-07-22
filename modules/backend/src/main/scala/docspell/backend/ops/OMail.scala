/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.ops.OMail._
import docspell.common._
import docspell.store._
import docspell.store.queries.QMails
import docspell.store.records._
import docspell.store.syntax.MimeTypes._

import bitpeace.{FileMeta, RangeDef}
import emil._

trait OMail[F[_]] {

  def getSmtpSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]]

  def findSmtpSettings(accId: AccountId, name: Ident): OptionT[F, RUserEmail]

  def createSmtpSettings(accId: AccountId, data: SmtpSettings): F[AddResult]

  def updateSmtpSettings(accId: AccountId, name: Ident, data: OMail.SmtpSettings): F[Int]

  def deleteSmtpSettings(accId: AccountId, name: Ident): F[Int]

  def getImapSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserImap]]

  def findImapSettings(accId: AccountId, name: Ident): OptionT[F, RUserImap]

  def createImapSettings(accId: AccountId, data: ImapSettings): F[AddResult]

  def updateImapSettings(accId: AccountId, name: Ident, data: OMail.ImapSettings): F[Int]

  def deleteImapSettings(accId: AccountId, name: Ident): F[Int]

  def sendMail(accId: AccountId, name: Ident, m: ItemMail): F[SendResult]

  def getSentMailsForItem(accId: AccountId, itemId: Ident): F[Vector[Sent]]

  def getSentMail(accId: AccountId, mailId: Ident): OptionT[F, Sent]

  def deleteSentMail(accId: AccountId, mailId: Ident): F[Int]
}

object OMail {

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
    def filter(v: Vector[(RAttachment, FileMeta)]): Vector[(RAttachment, FileMeta)]
  }
  object AttachSelection {
    case object All extends AttachSelection {
      def filter(v: Vector[(RAttachment, FileMeta)]): Vector[(RAttachment, FileMeta)] = v
    }
    case class Selected(ids: List[Ident]) extends AttachSelection {
      def filter(v: Vector[(RAttachment, FileMeta)]): Vector[(RAttachment, FileMeta)] = {
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

    def toRecord(accId: AccountId) =
      RUserEmail.fromAccount(
        accId,
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

    def toRecord(accId: AccountId) =
      RUserImap.fromAccount(
        accId,
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
          accId: AccountId,
          nameQ: Option[String]
      ): F[Vector[RUserEmail]] =
        store.transact(RUserEmail.findByAccount(accId, nameQ))

      def findSmtpSettings(accId: AccountId, name: Ident): OptionT[F, RUserEmail] =
        OptionT(store.transact(RUserEmail.getByName(accId, name)))

      def createSmtpSettings(accId: AccountId, s: SmtpSettings): F[AddResult] =
        (for {
          ru <- OptionT(store.transact(s.toRecord(accId).value))
          ins    = RUserEmail.insert(ru)
          exists = RUserEmail.exists(ru.uid, ru.name)
          res <- OptionT.liftF(store.add(ins, exists))
        } yield res).getOrElse(AddResult.Failure(new Exception("User not found")))

      def updateSmtpSettings(
          accId: AccountId,
          name: Ident,
          data: SmtpSettings
      ): F[Int] = {
        val op = for {
          um <- OptionT(RUserEmail.getByName(accId, name))
          ru <- data.toRecord(accId)
          n  <- OptionT.liftF(RUserEmail.update(um.id, ru))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }

      def deleteSmtpSettings(accId: AccountId, name: Ident): F[Int] =
        store.transact(RUserEmail.delete(accId, name))

      def getImapSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserImap]] =
        store.transact(RUserImap.findByAccount(accId, nameQ))

      def findImapSettings(accId: AccountId, name: Ident): OptionT[F, RUserImap] =
        OptionT(store.transact(RUserImap.getByName(accId, name)))

      def createImapSettings(accId: AccountId, data: ImapSettings): F[AddResult] =
        (for {
          ru <- OptionT(store.transact(data.toRecord(accId).value))
          ins    = RUserImap.insert(ru)
          exists = RUserImap.exists(ru.uid, ru.name)
          res <- OptionT.liftF(store.add(ins, exists))
        } yield res).getOrElse(AddResult.Failure(new Exception("User not found")))

      def updateImapSettings(
          accId: AccountId,
          name: Ident,
          data: OMail.ImapSettings
      ): F[Int] = {
        val op = for {
          um <- OptionT(RUserImap.getByName(accId, name))
          ru <- data.toRecord(accId)
          n  <- OptionT.liftF(RUserImap.update(um.id, ru))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }

      def deleteImapSettings(accId: AccountId, name: Ident): F[Int] =
        store.transact(RUserImap.delete(accId, name))

      def sendMail(accId: AccountId, name: Ident, m: ItemMail): F[SendResult] = {

        val getSmtpSettings: OptionT[F, RUserEmail] =
          OptionT(store.transact(RUserEmail.getByName(accId, name)))

        def createMail(sett: RUserEmail): OptionT[F, Mail[F]] = {
          import _root_.emil.builder._

          for {
            _ <- OptionT.liftF(store.transact(RItem.existsById(m.item))).filter(identity)
            ras <- OptionT.liftF(
              store.transact(
                RAttachment.findByItemAndCollectiveWithMeta(m.item, accId.collective)
              )
            )
          } yield {
            val addAttach = m.attach.filter(ras).map { a =>
              Attach[F](
                Stream.emit(a._2).through(store.bitpeace.fetchData2(RangeDef.all))
              ).withFilename(a._1.name)
                .withLength(a._2.length)
                .withMimeType(a._2.mimetype.toLocal.toEmil)
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
              accId,
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
          mail    <- createMail(mailCfg)
          mid     <- OptionT.liftF(sendMail(mailCfg.toMailConfig, mail))
          res     <- mid.traverse(id => OptionT.liftF(storeMail(id, mailCfg)))
          conv = res.fold(identity, _.fold(identity, id => SendResult.Success(id)))
        } yield conv).getOrElse(SendResult.NotFound)
      }

      def getSentMailsForItem(accId: AccountId, itemId: Ident): F[Vector[Sent]] =
        store
          .transact(QMails.findMails(accId.collective, itemId))
          .map(_.map(t => Sent.create(t._1, t._2)))

      def getSentMail(accId: AccountId, mailId: Ident): OptionT[F, Sent] =
        OptionT(store.transact(QMails.findMail(accId.collective, mailId))).map(t =>
          Sent.create(t._1, t._2)
        )

      def deleteSentMail(accId: AccountId, mailId: Ident): F[Int] =
        store.transact(QMails.delete(accId.collective, mailId))
    })
}
