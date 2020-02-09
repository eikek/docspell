package docspell.backend.ops

import fs2.Stream
import cats.effect._
import cats.implicits._
import cats.data.OptionT
import emil._
import emil.javamail.syntax._
import bitpeace.{FileMeta, RangeDef}

import docspell.common._
import docspell.store._
import docspell.store.records._
import docspell.store.queries.QMails
import OMail.{ItemMail, Sent, SmtpSettings}

trait OMail[F[_]] {

  def getSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]]

  def findSettings(accId: AccountId, name: Ident): OptionT[F, RUserEmail]

  def createSettings(accId: AccountId, data: SmtpSettings): F[AddResult]

  def updateSettings(accId: AccountId, name: Ident, data: OMail.SmtpSettings): F[Int]

  def deleteSettings(accId: AccountId, name: Ident): F[Int]

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

  def apply[F[_]: Effect](store: Store[F], emil: Emil[F]): Resource[F, OMail[F]] =
    Resource.pure[F, OMail[F]](new OMail[F] {
      def getSettings(accId: AccountId, nameQ: Option[String]): F[Vector[RUserEmail]] =
        store.transact(RUserEmail.findByAccount(accId, nameQ))

      def findSettings(accId: AccountId, name: Ident): OptionT[F, RUserEmail] =
        OptionT(store.transact(RUserEmail.getByName(accId, name)))

      def createSettings(accId: AccountId, s: SmtpSettings): F[AddResult] =
        (for {
          ru     <- OptionT(store.transact(s.toRecord(accId).value))
          ins    = RUserEmail.insert(ru)
          exists = RUserEmail.exists(ru.uid, ru.name)
          res    <- OptionT.liftF(store.add(ins, exists))
        } yield res).getOrElse(AddResult.Failure(new Exception("User not found")))

      def updateSettings(accId: AccountId, name: Ident, data: SmtpSettings): F[Int] = {
        val op = for {
          um <- OptionT(RUserEmail.getByName(accId, name))
          ru <- data.toRecord(accId)
          n  <- OptionT.liftF(RUserEmail.update(um.id, ru))
        } yield n

        store.transact(op.value).map(_.getOrElse(0))
      }

      def deleteSettings(accId: AccountId, name: Ident): F[Int] =
        store.transact(RUserEmail.delete(accId, name))

      def sendMail(accId: AccountId, name: Ident, m: ItemMail): F[SendResult] = {

        val getSettings: OptionT[F, RUserEmail] =
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
              Attach[F](Stream.emit(a._2).through(store.bitpeace.fetchData2(RangeDef.all)))
                .withFilename(a._1.name)
                .withLength(a._2.length)
                .withMimeType(_root_.emil.MimeType.parse(a._2.mimetype.asString).toOption)
            }
            val fields: Seq[Trans[F]] = Seq(
              From(sett.mailFrom),
              Tos(m.recipients),
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
              Left(SendResult.StoreFailure(new Exception(s"Could not find user to save mail.")))
            case Left(ex) => Left(SendResult.StoreFailure(ex))
          }
        }

        (for {
          mailCfg <- getSettings
          mail    <- createMail(mailCfg)
          mid     <- OptionT.liftF(sendMail(mailCfg.toMailConfig, mail))
          res     <- mid.traverse(id => OptionT.liftF(storeMail(id, mailCfg)))
          conv    = res.fold(identity, _.fold(identity, id => SendResult.Success(id)))
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
