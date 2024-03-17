/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.scanmailbox

import cats.data.Kleisli
import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2._

import docspell.backend.ops.{OJoex, OUpload}
import docspell.common._
import docspell.joex.Config
import docspell.logging.Logger
import docspell.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.queries.QOrganization
import docspell.store.records._

import _root_.io.circe.syntax._
import emil.SearchQuery.{All, ReceivedDate}
import emil.SearchResult.searchResultMonoid
import emil.javamail.syntax._
import emil.{MimeType => _, _}

object ScanMailboxTask {
  val maxItems: Long = 7
  type Args = ScanMailboxArgs

  def apply[F[_]: Sync](
      cfg: Config.ScanMailbox,
      store: Store[F],
      emil: Emil[F],
      upload: OUpload[F],
      joex: OJoex[F]
  ): Task[F, Args, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(
          s"=== Start importing mails for user ${ctx.args.account.login.id}"
        )
        _ <- ctx.logger.debug(s"Settings: ${ctx.args.asJson.noSpaces}")
        mailCfg <- getMailSettings(ctx, store)
        folders = ctx.args.folders.mkString(", ")
        login = ctx.args.account.login
        imapConn = ctx.args.imapConnection
        _ <- ctx.logger.info(
          s"Reading mails for user ${login.id} from ${imapConn.id}/$folders"
        )
        _ <- importMails(cfg, mailCfg, emil, upload, joex, ctx, store)
      } yield ()
    }

  def onCancel[F[_]]: Task[F, ScanMailboxArgs, Unit] =
    Task.log(_.warn("Cancelling scan-mailbox task"))

  def getMailSettings[F[_]: Sync](ctx: Context[F, Args], store: Store[F]): F[RUserImap] =
    store
      .transact(RUserImap.getByName(ctx.args.account.userId, ctx.args.imapConnection))
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
      ctx: Context[F, Args],
      store: Store[F]
  ): F[Unit] = {
    val mailer = theEmil(mailCfg.toMailConfig)
    val impl = new Impl[F](cfg, ctx, store)
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

    def processFolder(acc: ScanResult, name: String): F[ScanResult] =
      if (acc.noneLeft(name)) acc.pure[F]
      else
        mailer
          .run(
            impl.handleFolder(theEmil.access, upload)(
              name,
              ctx.args.scanRecursively.getOrElse(false)
            )
          )
          .map(_ ++ acc)

    Stream
      .eval(getInitialInput)
      .flatMap(Stream.emits)
      .repeat
      .evalScan(ScanResult.empty)(processFolder)
      .takeThrough(result =>
        result.processed < cfg.maxMails && result.someLeft(inFolders.size)
      )
      .lastOr(ScanResult.empty)
      .evalMap { sr =>
        joex.notifyAllNodes *>
          (if (sr.processed >= cfg.maxMails)
             ctx.logger.warn(
               s"Reached server maximum of ${cfg.maxMails} processed mails. Processed ${sr.processed} mails."
             )
           else
             ctx.logger
               .info(s"Stopped after processing ${sr.processed} mails"))
      }
      .compile
      .drain
  }

  case class ScanResult(folders: List[(String, Int)], processed: Int) {

    def ++(sr: ScanResult): ScanResult = {
      val fs = (folders ++ sr.folders).sortBy(_._2).distinctBy(_._1)
      ScanResult(fs, processed + sr.processed)
    }

    def noneLeft(name: String): Boolean =
      folders.find(_._1 == name).exists(_._2 <= 0)

    def someLeft(inputFolders: Int) =
      ScanResult.empty == this || folders.exists(_._2 > 0) || inputFolders > folders.size

  }

  object ScanResult {
    val empty = ScanResult(Nil, 0)
    def apply(folder: String, processed: Int, left: Int): ScanResult =
      ScanResult(List(folder -> left), processed)
  }

  final private class Impl[F[_]: Sync](
      cfg: Config.ScanMailbox,
      ctx: Context[F, Args],
      store: Store[F]
  ) {

    private def logOp[C](f: Logger[F] => F[Unit]): MailOp[F, C, Unit] =
      MailOp(_ => f(ctx.logger))

    def handleFolder[C](a: Access[F, C], upload: OUpload[F])(
        name: String,
        scanRecursively: Boolean
    ): MailOp[F, C, ScanResult] =
      for {
        _ <- Kleisli.liftF(ctx.logger.info(s"Processing folder $name"))
        folder <- requireFolder(a)(name)
        search <-
          if (scanRecursively) searchMailsRecursively(a)(folder)
          else searchMails(a)(folder)
        items = search.mails.map(MailHeaderItem(_))
        headers <- Kleisli.liftF(
          filterSubjects(items).flatMap(filterMessageIds)
        )
        _ <- headers.traverse(handleOne(ctx.args, a, upload))
      } yield ScanResult(name, search.mails.size, search.count - search.mails.size)

    def requireFolder[C](a: Access[F, C])(name: String): MailOp[F, C, MailFolder] =
      if ("INBOX".equalsIgnoreCase(name)) a.getInbox
      else // TODO resolve sub-folders
        a.findFolder(None, name)
          .map(_.toRight(new Exception(s"Folder '$name' not found")))
          .mapF(_.rethrow)

    def searchMailsRecursively[C](
        a: Access[F, C]
    )(folder: MailFolder): MailOp[F, C, SearchResult[MailHeader]] =
      for {
        subFolders <- a.listFoldersRecursive(Some(folder))
        foldersToSearch = Vector(folder) ++ subFolders
        search <- foldersToSearch.traverse(searchMails(a))
      } yield searchResultMonoid.combineAll(search)

    def searchMails[C](
        a: Access[F, C]
    )(folder: MailFolder): MailOp[F, C, SearchResult[MailHeader]] = {
      val q = ctx.args.receivedSince match {
        case Some(d) =>
          Timestamp.current[F].map(now => ReceivedDate >= now.minus(d).value)
        case None => All.pure[F]
      }

      for {
        _ <- logOp(
          _.debug(s"Searching next ${cfg.mailBatchSize} mails in ${folder.name}.")
        )
        query <- Kleisli.liftF(q)
        mails <- a.search(folder, cfg.mailBatchSize)(query)
        _ <- logOp(
          _.debug(
            s"Found ${mails.count} mails in folder. Reading first ${mails.mails.size}"
          )
        )
      } yield mails
    }

    def filterSubjects(headers: Vector[MailHeaderItem]): F[Vector[MailHeaderItem]] =
      ctx.args.subjectFilter match {
        case Some(sf) =>
          def check(mh: MailHeaderItem): F[MailHeaderItem] =
            if (mh.notProcess || sf.matches(caseSensitive = false)(mh.mh.subject))
              mh.pure[F]
            else
              ctx.logger.debug(
                s"Excluding mail '${mh.mh.subject}', it doesn't match the subject filter."
              ) *> mh.skip.pure[F]
          ctx.logger.info(
            s"Filtering mails on subject using filter: ${sf.asString}"
          ) *> headers.traverse(check)

        case None =>
          ctx.logger.debug("Not matching on subjects. No filter given") *> headers.pure[F]
      }

    def filterMessageIds(headers: Vector[MailHeaderItem]): F[Vector[MailHeaderItem]] =
      NonEmptyList.fromFoldable(headers.flatMap(_.mh.messageId)) match {
        case Some(nl) =>
          for {
            archives <- store.transact(
              RAttachmentArchive
                .findByMessageIdAndCollective(nl, ctx.args.account.collectiveId)
            )
            existing = archives.flatMap(_.messageId).toSet
            mails <- headers
              .traverse(mh =>
                if (mh.process && mh.mh.messageId.forall(existing.contains))
                  ctx.logger.debug(
                    s"Excluding mail '${mh.mh.subject}' it has been imported in the past.'"
                  ) *> mh.skip.pure[F]
                else mh.pure[F]
              )
          } yield mails

        case None =>
          headers.pure[F]
      }

    def getDirection(mh: MailHeader): F[Direction] = {
      val out: OptionT[F, Direction] =
        for {
          from <- OptionT.fromOption[F](mh.from)
          _ <- OptionT(
            store.transact(
              QOrganization
                .findPersonByContact(
                  ctx.args.account.collectiveId,
                  from.address,
                  Some(ContactKind.Email),
                  Some(NonEmptyList.of(PersonUse.concerning))
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

    def postHandle[C](a: Access[F, C])(mh: MailHeaderItem): MailOp[F, C, Unit] = {
      val postHandleAll = ctx.args.postHandleAll.exists(identity)
      ctx.args.targetFolder match {
        case Some(tf) if postHandleAll || mh.process =>
          logOp(
            _.debug(s"Post handling mail: ${mh.mh.subject} - moving to folder: $tf")
          )
            .flatMap(_ =>
              a.getOrCreateFolder(None, tf).flatMap(folder => a.moveMail(mh.mh, folder))
            )
        case None if ctx.args.deleteMail && (postHandleAll || mh.process) =>
          logOp(_.debug(s"Post handling mail: ${mh.mh.subject} - deleting mail."))
            .flatMap(_ =>
              a.deleteMail(mh.mh).flatMapF { r =>
                if (r.count == 0)
                  ctx.logger.warn(s"Mail could not be deleted!")
                else ().pure[F]
              }
            )
        case _ =>
          logOp(_.debug(s"Post handling mail: ${mh.mh.subject} - no handling defined!"))
      }
    }

    def submitMail(upload: OUpload[F], args: Args)(
        mail: Mail[F]
    ): F[OUpload.UploadResult] = {
      val file = OUpload.File(
        Some(mail.header.subject + ".eml"),
        Some(MimeType.emls.head),
        mail.toByteStream
      )
      for {
        _ <- ctx.logger.debug(s"Submitting mail '${mail.header.subject}'")
        dir <- getDirection(mail.header)
        meta = OUpload.UploadMeta(
          Some(dir),
          s"mailbox-${ctx.args.account.login.id}",
          args.itemFolder,
          Seq.empty,
          skipDuplicates = true,
          args.fileFilter.getOrElse(Glob.all),
          args.tags.getOrElse(Nil),
          args.language,
          args.attachmentsOnly,
          None,
          None
        )
        data = OUpload.UploadData(
          multiple = false,
          meta = meta,
          files = Vector(file),
          priority = Priority.Low,
          tracker = None
        )
        res <- upload.submit(
          data,
          ctx.args.account.collectiveId,
          ctx.args.account.userId.some,
          None
        )
      } yield res
    }

    def handleOne[C](args: Args, a: Access[F, C], upload: OUpload[F])(
        mh: MailHeaderItem
    ): MailOp[F, C, Unit] =
      for {
        mail <- a.loadMail(mh.mh)
        res <- mail match {
          case Some(m) if mh.process =>
            Kleisli.liftF(submitMail(upload, args)(m).attempt)
          case Some(_) =>
            Kleisli.liftF(Either.right(mh).pure[F])
          case None =>
            MailOp.pure[F, C, Either[Throwable, OUpload.UploadResult]](
              Either.left(new Exception(s"Mail not found"))
            )
        }
        _ <- res.fold(
          ex =>
            Kleisli.liftF(
              ctx.logger.warn(s"Error submitting '${mh.mh.subject}': ${ex.getMessage}")
            ),
          _ => postHandle(a)(mh)
        )
      } yield ()
  }

  case class MailHeaderItem(mh: MailHeader, process: Boolean = true) {
    def skip = copy(process = false)
    def notProcess = !process
  }
}
