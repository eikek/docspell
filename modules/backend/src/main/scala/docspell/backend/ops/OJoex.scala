/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend.ops

import scala.concurrent.ExecutionContext

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common.{Ident, NodeType}
import docspell.joexapi.client.JoexClient
import docspell.store.Store
import docspell.store.records.RNode

trait OJoex[F[_]] {

  def notifyAllNodes: F[Unit]

  def cancelJob(job: Ident, worker: Ident): F[Boolean]

}

object OJoex {

  def apply[F[_]: Sync](client: JoexClient[F], store: Store[F]): Resource[F, OJoex[F]] =
    Resource.pure[F, OJoex[F]](new OJoex[F] {
      def notifyAllNodes: F[Unit] =
        for {
          nodes <- store.transact(RNode.findAll(NodeType.Joex))
          _     <- nodes.toList.traverse(n => client.notifyJoexIgnoreErrors(n.url))
        } yield ()

      def cancelJob(job: Ident, worker: Ident): F[Boolean] =
        (for {
          node   <- OptionT(store.transact(RNode.findById(worker)))
          cancel <- OptionT.liftF(client.cancelJob(node.url, job))
        } yield cancel.success).getOrElse(false)
    })

  def create[F[_]: Async](
      ec: ExecutionContext,
      store: Store[F]
  ): Resource[F, OJoex[F]] =
    JoexClient.resource(ec).flatMap(client => apply(client, store))

}
