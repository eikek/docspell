/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.hk

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.logging.Logger
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.records._

import org.http4s.blaze.client.BlazeClientBuilder
import org.http4s.client.Client

object CheckNodesTask {
  def apply[F[_]: Async](
      cfg: HouseKeepingConfig.CheckNodes,
      store: Store[F]
  ): Task[F, Unit, CleanupResult] =
    Task { ctx =>
      if (cfg.enabled)
        for {
          _ <- ctx.logger.info("Check nodes reachability")
          ec = scala.concurrent.ExecutionContext.global
          _ <- BlazeClientBuilder[F].withExecutionContext(ec).resource.use { client =>
            checkNodes(ctx.logger, store, client)
          }
          _ <- ctx.logger.info(
            s"Remove nodes not found more than ${cfg.minNotFound} times"
          )
          n <- removeNodes(store, cfg)
          _ <- ctx.logger.info(s"Removed $n nodes")
        } yield CleanupResult.of(n)
      else
        ctx.logger.info("CheckNodes task is disabled in the configuration") *>
          CleanupResult.disabled.pure[F]

    }

  def checkNodes[F[_]: Async](
      logger: Logger[F],
      store: Store[F],
      client: Client[F]
  ): F[Unit] =
    store
      .transact(RNode.streamAll)
      .evalMap(node =>
        checkNode(logger, client)(node.url)
          .flatMap(seen =>
            if (seen) store.transact(RNode.resetNotFound(node.id))
            else store.transact(RNode.incrementNotFound(node.id))
          )
      )
      .compile
      .drain

  def checkNode[F[_]: Async](logger: Logger[F], client: Client[F])(
      url: LenientUri
  ): F[Boolean] = {
    val apiVersion = url / "api" / "info" / "version"
    for {
      res <- client.expect[String](apiVersion.asString).attempt
      _ <- res.fold(
        ex => logger.info(s"Node ${url.asString} not found: ${ex.getMessage}"),
        _ => logger.info(s"Node ${url.asString} is reachable")
      )
    } yield res.isRight
  }

  def removeNodes[F[_]](
      store: Store[F],
      cfg: HouseKeepingConfig.CheckNodes
  ): F[Int] =
    store.transact(RNode.deleteNotFound(cfg.minNotFound))

}
