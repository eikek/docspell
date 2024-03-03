/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._
import fs2.io.file.Files

import docspell.addons._
import docspell.backend.joex.AddonOps.{AddonRunConfigRef, ExecResult}
import docspell.backend.ops.OAttachment
import docspell.common._
import docspell.common.bc.BackendCommandRunner
import docspell.common.exec.Env
import docspell.common.util.Directory
import docspell.logging.Logger
import docspell.scheduler.JobStore
import docspell.store.Store
import docspell.store.file.FileUrlReader
import docspell.store.records.AddonRunConfigResolved

trait AddonOps[F[_]] {

  def execAll(
      collective: CollectiveId,
      trigger: Set[AddonTriggerType],
      runConfigIds: Set[Ident],
      logger: Option[Logger[F]]
  )(
      middleware: Middleware[F]
  ): F[ExecResult]

  def execById(collective: CollectiveId, runConfigId: Ident, logger: Logger[F])(
      middleware: Middleware[F]
  ): F[ExecResult]

  /** Find enabled addon run config references to be executed. Can be additionally
    * filtered by given ids and triggers.
    */
  def findAddonRefs(
      collective: CollectiveId,
      trigger: Set[AddonTriggerType],
      runConfigIds: Set[Ident]
  ): F[List[AddonRunConfigRef]]

  /** Find enabled addon run config reference given an addon task id */
  def findAddonRef(
      collective: CollectiveId,
      runConfigId: Ident
  ): F[Option[AddonRunConfigRef]]

  /** Creates an executor for addons given a configuration. */
  def getExecutor(cfg: AddonExecutorConfig): F[AddonExecutor[F]]

}

object AddonOps {
  case class AddonRunConfigRef(
      id: Ident,
      collective: CollectiveId,
      userId: Option[Ident],
      name: String,
      refs: List[AddonRef]
  )

  object AddonRunConfigRef {
    def fromResolved(r: AddonRunConfigResolved): AddonRunConfigRef =
      AddonRunConfigRef(
        r.config.id,
        r.config.cid,
        r.config.userId,
        r.config.name,
        r.refs.map(ref => AddonRef(ref.archive.asArchive, ref.ref.args))
      )
  }

  case class ExecResult(
      result: List[AddonExecutionResult],
      runConfigs: List[AddonRunConfigRef]
  ) {
    lazy val combined = result.combineAll
  }

  object ExecResult {
    def runConfigNotFound(id: Ident): ExecResult =
      ExecResult(
        AddonExecutionResult(
          AddonResult.executionFailed(
            new Exception(s"Addon run config ${id.id} not found.")
          ) :: Nil,
          pure = false
        ) :: Nil,
        Nil
      )
  }

  def apply[F[_]: Async: Files](
      cfg: AddonEnvConfig,
      store: Store[F],
      cmdRunner: BackendCommandRunner[F, Unit],
      attachment: OAttachment[F],
      jobStore: JobStore[F]
  ): AddonOps[F] =
    new AddonOps[F] with LoggerExtension {
      private[this] val logger = docspell.logging.getLogger[F]

      private val urlReader = FileUrlReader(store.fileRepo)
      private val postProcess = AddonPostProcess(cmdRunner, store, attachment, jobStore)
      private val prepare = new AddonPrepare[F](store)

      def execAll(
          collective: CollectiveId,
          trigger: Set[AddonTriggerType],
          runConfigIds: Set[Ident],
          logger: Option[Logger[F]]
      )(
          custom: Middleware[F]
      ): F[ExecResult] =
        for {
          runCfgs <- findAddonRefs(collective, trigger, runConfigIds)
          log = logger.getOrElse(this.logger)
          _ <- log.info(s"Running ${runCfgs.size} addon tasks for trigger $trigger")

          results <- runCfgs.traverse(r => execRunConfig(log, r, custom))
        } yield ExecResult(results.flatMap(_.result), runCfgs)

      def execById(collective: CollectiveId, runConfigId: Ident, logger: Logger[F])(
          custom: Middleware[F]
      ): F[ExecResult] =
        (for {
          runCfg <- OptionT(findAddonRef(collective, runConfigId))
          execRes <- OptionT.liftF(execRunConfig(logger, runCfg, custom))
        } yield execRes).getOrElse(ExecResult.runConfigNotFound(runConfigId))

      def execRunConfig(
          logger: Logger[F],
          runCfg: AddonRunConfigRef,
          custom: Middleware[F]
      ): F[ExecResult] =
        for {
          executor <- getExecutor(cfg.executorConfig)
          log = logger.withRunConfig(runCfg)
          result <-
            Directory.temp(cfg.workingDir, "addon-output-").use { outDir =>
              val cacheDir = cfg.cacheDir / runCfg.id.id
              val inputEnv =
                InputEnv(runCfg.refs, cfg.workingDir, outDir, cacheDir, Env.empty)

              for {
                middleware <- createMiddleware(custom, runCfg)
                res <- middleware(executor.execute(log)).run(inputEnv)
                _ <- log.debug(s"Addon result: $res")
                _ <- postProcess.onResult(log, runCfg.collective, res, outDir)
              } yield res
            }
          execRes = ExecResult(List(result), List(runCfg))
        } yield execRes

      def createMiddleware(
          custom: Middleware[F],
          runCfg: AddonRunConfigRef
      ): F[Middleware[F]] = for {
        dscMW <- prepare.createDscEnv(runCfg, cfg.executorConfig.runTimeout)
        mm = dscMW >> custom >> prepare.logResult(logger, runCfg) >> Middleware
          .ephemeralRun[F]
      } yield mm

      def getExecutor(cfg: AddonExecutorConfig): F[AddonExecutor[F]] =
        Async[F].pure(AddonExecutor(cfg, urlReader))

      def findAddonRefs(
          collective: CollectiveId,
          trigger: Set[AddonTriggerType],
          runConfigIds: Set[Ident]
      ): F[List[AddonRunConfigRef]] =
        store
          .transact(
            AddonRunConfigResolved.findAllForCollective(
              collective,
              enabled = true.some,
              trigger,
              runConfigIds
            )
          )
          .map(_.map(AddonRunConfigRef.fromResolved))

      def findAddonRef(
          collective: CollectiveId,
          runConfigId: Ident
      ): F[Option[AddonRunConfigRef]] =
        OptionT(
          store
            .transact(
              AddonRunConfigResolved.findById(
                runConfigId,
                collective,
                enabled = Some(true)
              )
            )
        ).map(AddonRunConfigRef.fromResolved).value
    }
}
