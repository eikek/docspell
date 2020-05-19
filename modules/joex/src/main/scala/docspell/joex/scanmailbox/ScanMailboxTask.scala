package docspell.joex.scanmailbox

import fs2._
import cats.implicits._
import cats.effect._
import emil.{MimeType => _, _}
import emil.javamail.syntax._
import emil.SearchQuery.{All, ReceivedDate}

import docspell.common._
import docspell.backend.ops.{OJoex, OUpload}
import docspell.store.records._
import docspell.joex.Config
import docspell.joex.scheduler.{Context, Task}
import docspell.store.queries.QOrganization
import cats.data.Kleisli
import cats.data.NonEmptyList
import cats.data.OptionT

object ScanMailboxTask {
  val maxItems: Long = 7
  type Args = ScanMailboxArgs

  def apply[F[_]: Sync](
      cfg: Config.ScanMailbox,
      emil: Emil[F],
      upload: OUpload[F],
      joex: OJoex[F]
  ): Task[F, Args, Unit] =
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
        _ <- importMails(cfg, mailCfg, emil, upload, joex, ctx)
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
      cfg: Config.ScanMailbox,
      mailCfg: RUserImap,
      theEmil: Emil[F],
      upload: OUpload[F],
      joex: OJoex[F],
      ctx: Context[F, Args]
  ): F[Unit] = {
    val mailer    = theEmil(mailCfg.toMailConfig)
    val impl      = new Impl[F](cfg, ctx)
    val inFolders = ctx.args.folders.take(cfg.maxFolders)

    val getInitialInput =
      for {
        _ <-
          if (inFolders.size != ctx.args.folders.size)
            ctx.logger.warn(
              s"More than ${cfg.maxFolders} submitted. Only first ${cfg.maxFolders} will be scanned."
            )
          else ().pure[F]
      } yield inFolders

    def processFolders(in: Seq[String]): Stream[F, ScanResult] = {
      val pass =
        for {
          name <- Stream.emits(in).covary[F]
          res <-
            Stream.eval(mailer.run(impl.handleFolder(theEmil.access, upload, joex)(name)))
        } yield res

      pass
        .fold1(_ ++ _)
        .flatMap { sr =>
          if (sr.folders.isEmpty) Stream.emit(sr)
          else processFolders(sr.folders)
        }
        .takeWhile(_.processed < cfg.maxMails)
    }

    Stream.eval(getInitialInput).flatMap(processFolders).compile.drain
  }

  case class ScanResult(folders: Seq[String], processed: Int, left: Int) {

    /** Removes folders where nothing is left to process */
    def ++(sr: ScanResult): ScanResult =
      if (left == 0) ScanResult(sr.folders, processed + sr.processed, sr.left)
      else if (sr.left == 0) ScanResult(folders, processed + sr.processed, left)
      else ScanResult(folders ++ sr.folders, processed + sr.processed, left + sr.left)
  }
  object ScanResult {
    def apply(folder: String, processed: Int, left: Int): ScanResult =
      if (left <= 0) ScanResult(Seq.empty, processed, 0)
      else ScanResult(Seq(folder), processed, left)
  }

  final private class Impl[F[_]: Sync](cfg: Config.ScanMailbox, ctx: Context[F, Args]) {

    def handleFolder[C](a: Access[F, C], upload: OUpload[F], joex: OJoex[F])(
        name: String
    ): MailOp[F, C, ScanResult] =
      for {
        _       <- Kleisli.liftF(ctx.logger.info(s"Processing folder $name"))
        folder  <- requireFolder(a)(name)
        search  <- searchMails(a)(folder)
        headers <- Kleisli.liftF(filterMessageIds(search.mails))
        _       <- headers.traverse(handleOne(a, upload))
        _       <- Kleisli.liftF(joex.notifyAllNodes)
      } yield ScanResult(name, headers.size, search.count - search.mails.size)

    def requireFolder[C](a: Access[F, C])(name: String): MailOp[F, C, MailFolder] =
      if ("INBOX".equalsIgnoreCase(name)) a.getInbox
      else //TODO resolve sub-folders
        a.findFolder(None, name)
          .map(_.toRight(new Exception(s"Folder '$name' not found")))
          .mapF(_.rethrow)

    def searchMails[C](
        a: Access[F, C]
    )(folder: MailFolder): MailOp[F, C, SearchResult[MailHeader]] = {
      val q = ctx.args.receivedSince match {
        case Some(d) =>
          Timestamp.current[F].map(now => ReceivedDate >= now.minus(d).value)
        case None => All.pure[F]
      }

      for {
        _ <- Kleisli.liftF(
          ctx.logger.info(s"Searching next ${cfg.mailChunkSize} mails in ${folder.name}.")
        )
        query <- Kleisli.liftF(q)
        mails <- a.search(folder, cfg.mailChunkSize)(query)
      } yield mails
    }

    def filterMessageIds(headers: Vector[MailHeader]): F[Vector[MailHeader]] =
      NonEmptyList.fromFoldable(headers.flatMap(_.messageId)) match {
        case Some(nl) =>
          for {
            archives <- ctx.store.transact(
              RAttachmentArchive
                .findByMessageIdAndCollective(nl, ctx.args.account.collective)
            )
            existing = archives.flatMap(_.messageId).toSet
            mails    = headers.filterNot(mh => mh.messageId.forall(existing.contains))
            _ <- headers.size - mails.size match {
              case 0 => ().pure[F]
              case n => ctx.logger.info(s"Excluded $n mails since items for them already exist.")
            }
          } yield mails

        case None =>
          ctx.logger.info("No mails found") *> headers.pure[F]
      }

    def getDirection(mh: MailHeader): F[Direction] = {
      val out: OptionT[F, Direction] =
        for {
          from <- OptionT.fromOption[F](mh.from)
          _ <- OptionT(
            ctx.store.transact(
              QOrganization
                .findPersonByContact(
                  ctx.args.account.collective,
                  from.address,
                  Some(ContactKind.Email),
                  Some(true)
                )
                .take(1)
                .compile
                .last
            )
          )
        } yield Direction.Outgoing

      OptionT
        .fromOption[F](ctx.args.direction)
        .orElse(out)
        .getOrElse(Direction.Incoming)
    }

    def postHandle[C](a: Access[F, C])(mh: MailHeader): MailOp[F, C, Unit] =
      ctx.args.targetFolder match {
        case Some(tf) =>
          a.getOrCreateFolder(None, tf).flatMap(folder => a.moveMail(mh, folder))
        case None if ctx.args.deleteMail =>
          a.deleteMail(mh).flatMapF { r =>
            if (r.count == 0)
              ctx.logger.warn(s"Mail '${mh.subject}' could not be deleted")
            else ().pure[F]
          }
        case None =>
          MailOp.pure(())
      }

    def submitMail(upload: OUpload[F])(mail: Mail[F]): F[OUpload.UploadResult] = {
      val file = OUpload.File(
        Some(mail.header.subject + ".eml"),
        Some(MimeType.eml),
        mail.toByteStream
      )
      for {
        _   <- ctx.logger.debug(s"Submitting mail '${mail.header.subject}'")
        dir <- getDirection(mail.header)
        meta = OUpload.UploadMeta(
          Some(dir),
          s"mailbox-${ctx.args.account.user.id}",
          Seq.empty
        )
        data = OUpload.UploadData(
          multiple = false,
          meta = meta,
          files = Vector(file),
          priority = Priority.Low,
          tracker = None
        )
        res <- upload.submit(data, ctx.args.account, false)
      } yield res
    }

    def handleOne[C](a: Access[F, C], upload: OUpload[F])(
        mh: MailHeader
    ): MailOp[F, C, Unit] =
      for {
        mail <- a.loadMail(mh)
        res <- mail match {
          case Some(m) =>
            Kleisli.liftF(submitMail(upload)(m).attempt)
          case None =>
            MailOp.pure[F, C, Either[Throwable, OUpload.UploadResult]](
              Either.left(new Exception(s"Mail not found"))
            )
        }
        _ <- res.fold(
          ex =>
            Kleisli.liftF(
              ctx.logger.warn(s"Error submitting '${mh.subject}': ${ex.getMessage}")
            ),
          _ => postHandle(a)(mh)
        )
      } yield ()

    // limit number of folders
    // limit number of mails to retrieve per folder
    // per folder:
    //   fetch X mails
    //     check via msgId if already present; if not:
    //     load mail
    //     serialize to *bytes*
    //     store mail in queue
    //     move mail or delete or do nothing
    //     errors: log and keep going
    //   errors per folder fetch: fail the task
    //   notifiy joex after each batch
    //
    // no message id? make hash over complete mail or just import it
  }
}
