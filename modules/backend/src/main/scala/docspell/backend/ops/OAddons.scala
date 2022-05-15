/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.{EitherT, NonEmptyList, OptionT}
import cats.effect._
import cats.syntax.all._

import docspell.addons.{AddonMeta, AddonTriggerType}
import docspell.backend.ops.AddonValidationError._
import docspell.backend.ops.OAddons._
import docspell.backend.{Config, JobFactory}
import docspell.common._
import docspell.logging.Logger
import docspell.scheduler.JobStore
import docspell.scheduler.usertask.{UserTask, UserTaskScope, UserTaskStore}
import docspell.store.Store
import docspell.store.file.FileUrlReader
import docspell.store.records._

import com.github.eikek.calev.CalEvent

trait OAddons[F[_]] {

  /** Registers a new addon. An error is returned if an addon with this url already
    * exists.
    */
  def registerAddon(
      collective: Ident,
      url: LenientUri,
      logger: Option[Logger[F]]
  ): F[AddonValidationResult[(RAddonArchive, AddonMeta)]]

  /** Refreshes an existing addon by downloading it again and updating metadata. */
  def refreshAddon(
      collective: Ident,
      addonId: Ident
  ): F[AddonValidationResult[(RAddonArchive, AddonMeta)]]

  /** Look into the addon at the given url and return its metadata. */
  def inspectAddon(
      collective: Ident,
      url: LenientUri
  ): F[AddonValidationResult[AddonMeta]]

  /** Deletes the addon if it exists. */
  def deleteAddon(collective: Ident, addonId: Ident): F[Boolean]

  def getAllAddons(collective: Ident): F[List[RAddonArchive]]

  /** Inserts or updates the addon run configuration. If it already exists (and the given
    * id is non empty), it will be completely replaced with the given one.
    */
  def upsertAddonRunConfig(
      collective: Ident,
      runConfig: AddonRunInsert
  ): F[AddonRunConfigResult[Ident]]

  /** Deletes this task from the database. */
  def deleteAddonRunConfig(collective: Ident, runConfigId: Ident): F[Boolean]

  def getAllAddonRunConfigs(collective: Ident): F[List[AddonRunInfo]]

  def runAddonForItem(
      account: AccountId,
      itemIds: NonEmptyList[Ident],
      addonRunConfigIds: Set[Ident]
  ): F[Unit]
}

object OAddons {
  val scheduledAddonTaskName: Ident =
    ScheduledAddonTaskArgs.taskName

  case class AddonRunInsert(
      id: Ident,
      name: String,
      enabled: Boolean,
      userId: Option[Ident],
      schedule: Option[CalEvent],
      triggered: NonEmptyList[AddonTriggerType],
      addons: NonEmptyList[AddonArgs]
  ) {

    def isScheduled: Boolean =
      triggered.exists(_ == AddonTriggerType.Scheduled)
  }
  case class AddonArgs(addonId: Ident, args: String)

  case class AddonRunInfo(
      id: Ident,
      name: String,
      enabled: Boolean,
      userId: Option[Ident],
      schedule: Option[CalEvent],
      triggered: List[AddonTriggerType],
      addons: List[(RAddonArchive, RAddonRunConfigAddon)]
  )
  object AddonRunInfo {
    def fromRunConfigData(
        timer: Option[CalEvent],
        addons: List[(RAddonArchive, RAddonRunConfigAddon)]
    )(t: AddonRunConfigData): AddonRunInfo =
      AddonRunInfo(
        id = t.runConfig.id,
        name = t.runConfig.name,
        enabled = t.runConfig.enabled,
        userId = t.runConfig.userId,
        schedule = timer,
        triggered = t.triggers.map(_.trigger),
        addons = addons
      )
  }

  type AddonRunConfigResult[A] = Either[AddonRunConfigError, A]
  object AddonRunConfigResult {
    def success[A](value: A): AddonRunConfigResult[A] = Right(value)
    def failure[A](error: AddonRunConfigError): AddonRunConfigResult[A] = error.toLeft[A]
  }

  type AddonValidationResult[A] = Either[AddonValidationError, A]
  object AddonValidationResult {
    def success[A](value: A): AddonValidationResult[A] = Right(value)
    def failure[A](error: AddonValidationError): AddonValidationResult[A] = Left(error)
  }

  def apply[F[_]: Async](
      cfg: Config.Addons,
      store: Store[F],
      userTasks: UserTaskStore[F],
      jobStore: JobStore[F],
      joex: OJoex[F]
  ): OAddons[F] =
    new OAddons[F] {
      private[this] val logger = docspell.logging.getLogger[F]
      private val urlReader = FileUrlReader(store.fileRepo)
      private val zip = MimeType.zip.asString
      private val addonValidate = new AddonValidate[F](cfg, store, joex)

      def getAllAddonRunConfigs(collective: Ident): F[List[AddonRunInfo]] =
        for {
          all <- store.transact(AddonRunConfigData.findAll(collective))
          runConfigIDs = all.map(_.runConfig.id).toSet
          archiveIds = all.flatMap(_.addons.map(_.addonId)).distinct
          archives <- NonEmptyList
            .fromList(archiveIds)
            .fold(List.empty[RAddonArchive].pure[F])(ids =>
              store.transact(RAddonArchive.findByIds(collective, ids))
            )
          archivesMap = archives.groupBy(_.id)
          ptask <- userTasks
            .getAll(UserTaskScope.collective(collective))
            .filter(ut => runConfigIDs.contains(ut.id))
            .map(ut => ut.id -> ut)
            .compile
            .toList
            .map(_.toMap)
          result = all.map { t =>
            AddonRunInfo.fromRunConfigData(
              ptask.get(t.runConfig.id).map(_.timer),
              t.addons.map(raa => (archivesMap(raa.addonId).head, raa))
            )(t)
          }
        } yield result

      def upsertAddonRunConfig(
          collective: Ident,
          runConfig: AddonRunInsert
      ): F[AddonRunConfigResult[Ident]] = {
        val insertDataRaw = AddonRunConfigData(
          RAddonRunConfig(
            runConfig.id,
            collective,
            runConfig.userId,
            runConfig.name,
            runConfig.enabled,
            Timestamp.Epoch
          ),
          runConfig.addons.zipWithIndex.map { case (a, index) =>
            RAddonRunConfigAddon(Ident.unsafe(""), runConfig.id, a.addonId, a.args, index)
          }.toList,
          runConfig.triggered
            .map(t => RAddonRunConfigTrigger(Ident.unsafe(""), runConfig.id, t))
            .toList
        )

        val upsert = for {
          userId <-
            OptionT
              .fromOption(runConfig.userId)
              .flatMapF(uid => store.transact(RUser.getIdByIdOrLogin(uid)))
              .map(_.uid)
              .value
          insertData =
            insertDataRaw.copy(runConfig =
              insertDataRaw.runConfig.copy(userId = userId.orElse(runConfig.userId))
            )
          id <-
            OptionT(store.transact(RAddonRunConfig.findById(collective, runConfig.id)))
              .map(rt =>
                AddonRunConfigData(
                  rt.copy(
                    userId = insertData.runConfig.userId,
                    name = insertData.runConfig.name,
                    enabled = insertData.runConfig.enabled
                  ),
                  insertData.addons,
                  insertData.triggers
                )
              )
              .semiflatMap(rt =>
                store.transact(AddonRunConfigData.update(rt).as(rt.runConfig.id))
              )
              .getOrElseF(store.transact(AddonRunConfigData.insert(insertData)))
        } yield id

        EitherT(AddonRunConfigValidate(store, collective)(runConfig))
          .semiflatMap(_ =>
            upsert.flatTap { runConfigId =>
              runConfig.schedule match {
                case Some(timer) =>
                  userTasks.updateTask(
                    UserTaskScope.collective(collective),
                    s"Addon task ${runConfig.name}".some,
                    UserTask(
                      runConfigId,
                      scheduledAddonTaskName,
                      true,
                      timer,
                      s"Running scheduled addon task ${runConfig.name}".some,
                      ScheduledAddonTaskArgs(collective, runConfigId)
                    )
                  )
                case None =>
                  userTasks.deleteTask(UserTaskScope.collective(collective), runConfigId)
              }
            }
          )
          .value
      }

      def deleteAddonRunConfig(collective: Ident, runConfigId: Ident): F[Boolean] = {
        val deleteRunConfig =
          (for {
            e <- OptionT(RAddonRunConfig.findById(collective, runConfigId))
            _ <- OptionT.liftF(RAddonRunConfigAddon.deleteAllForConfig(e.id))
            _ <- OptionT.liftF(RAddonRunConfigTrigger.deleteAllForConfig(e.id))
            _ <- OptionT.liftF(RAddonRunConfig.deleteById(collective, e.id))
          } yield true).getOrElse(false)

        for {
          deleted <- store.transact(deleteRunConfig)
          _ <-
            if (deleted)
              userTasks.deleteTask(UserTaskScope.collective(collective), runConfigId)
            else 0.pure[F]
        } yield deleted
      }

      def getAllAddons(collective: Ident): F[List[RAddonArchive]] =
        store.transact(RAddonArchive.listAll(collective))

      def deleteAddon(collective: Ident, addonId: Ident): F[Boolean] =
        store.transact(RAddonArchive.deleteById(collective, addonId)).map(_ > 0)

      def inspectAddon(
          collective: Ident,
          url: LenientUri
      ): F[AddonValidationResult[AddonMeta]] =
        addonValidate.fromUrl(collective, url, urlReader, checkExisting = false)

      def registerAddon(
          collective: Ident,
          url: LenientUri,
          logger: Option[Logger[F]]
      ): F[AddonValidationResult[(RAddonArchive, AddonMeta)]] = {
        val log = logger.getOrElse(this.logger)
        def validateAndInsert(file: FileKey, localUrl: LenientUri) =
          addonValidate.fromUrl(collective, url, urlReader, localUrl.some).flatMap {
            case Right(meta) =>
              insertAddon(collective, url, meta, file)
                .map(ar => AddonValidationResult.success(ar -> meta))

            case Left(error) =>
              store.fileRepo
                .delete(file)
                .as(AddonValidationResult.failure[(RAddonArchive, AddonMeta)](error))
          }

        log.info(s"Store addon file from '${url.asString} for ${collective.id}") *>
          storeAddonFromUrl(collective, url).flatMapF { file =>
            val localUrl = FileUrlReader.url(file)
            for {
              _ <- log.info(s"Validating addon…")
              res <- validateAndInsert(file, localUrl)
              _ <- log.info(s"Validation result: $res")
            } yield res
          }.value
      }

      def refreshAddon(
          collective: Ident,
          addonId: Ident
      ): F[AddonValidationResult[(RAddonArchive, AddonMeta)]] = {
        val findAddon = store
          .transact(RAddonArchive.findById(collective, addonId))
          .map(_.toRight(AddonNotFound))
        def validateAddon(aa: RAddonArchive): F[AddonValidationResult[AddonMeta]] =
          aa.originalUrl.fold(
            AddonValidationResult.failure[AddonMeta](RefreshLocalAddon).pure[F]
          )(url =>
            addonValidate.fromUrl(collective, url, urlReader, checkExisting = false)
          )

        EitherT(findAddon).flatMap { aa =>
          EitherT(validateAddon(aa))
            .flatMap(meta => refreshAddon(aa, meta).map(na => na -> meta))
        }.value
      }

      private def refreshAddon(
          r: RAddonArchive,
          meta: AddonMeta
      ): EitherT[F, AddonValidationError, RAddonArchive] =
        if (r.isUnchanged(meta)) EitherT.pure(r)
        else
          r.originalUrl match {
            case Some(url) =>
              EitherT(
                store
                  .transact(
                    RAddonArchive
                      .findByNameAndVersion(r.cid, meta.meta.name, meta.meta.version)
                  )
                  .map(
                    _.fold(().asRight[AddonValidationError])(rx => AddonExists(rx).toLeft)
                  )
              ).flatMap(_ =>
                storeAddonFromUrl(r.cid, url).flatMap { file =>
                  val nr = r.update(file, meta)
                  for {
                    _ <- EitherT(
                      store
                        .transact(RAddonArchive.update(nr))
                        .map(_.asRight[AddonValidationError])
                        .recoverWith { case ex =>
                          logger.warn(ex)(s"Storing addon metadata failed.") *>
                            store.fileRepo
                              .delete(file)
                              .as(
                                AddonExists(
                                  s"The addon '${nr.name}/${nr.version}' could not be stored",
                                  nr
                                ).toLeft
                              )
                        }
                    )
                    _ <- EitherT.liftF(store.fileRepo.delete(r.fileId))
                  } yield nr
                }
              )
            case None =>
              EitherT.leftT(RefreshLocalAddon.cast)
          }

      private def insertAddon(
          collective: Ident,
          url: LenientUri,
          meta: AddonMeta,
          file: FileKey
      ): F[RAddonArchive] =
        for {
          now <- Timestamp.current[F]
          aId <- Ident.randomId[F]
          record = RAddonArchive(
            aId,
            collective,
            file,
            url.some,
            meta,
            now
          )
          _ <- store
            .transact(RAddonArchive.insert(record, silent = false))
            .onError(_ => store.fileRepo.delete(file))
        } yield record

      private def storeAddonFromUrl(collective: Ident, url: LenientUri) =
        for {
          urlFile <- EitherT.pure(url.path.segments.lastOption)
          file <- EitherT(
            urlReader(url)
              .through(
                store.fileRepo.save(
                  collective,
                  FileCategory.Addon,
                  MimeTypeHint(urlFile, zip.some)
                )
              )
              .compile
              .lastOrError
              .attempt
              .map(_.leftMap(DownloadFailed(_).cast))
          )
        } yield file

      def runAddonForItem(
          account: AccountId,
          itemIds: NonEmptyList[Ident],
          addonRunConfigIds: Set[Ident]
      ): F[Unit] =
        for {
          jobs <- itemIds.traverse(id =>
            JobFactory.existingItemAddon(
              ItemAddonTaskArgs(account.collective, id, addonRunConfigIds),
              account
            )
          )
          _ <- jobStore.insertAllIfNew(jobs.map(_.encode).toList)
        } yield ()
    }
}
