/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.syntax.all._
import docspell.common.{Ident, LenientUri, NodeType}
import docspell.store.Store
import docspell.store.records.RNode

import org.log4s._

trait ONode[F[_]] {

  def register(appId: Ident, nodeType: NodeType, uri: LenientUri): F[Unit]

  def unregister(appId: Ident): F[Unit]
}

object ONode {
  private[this] val logger = getLogger

  def apply[F[_]: Async](store: Store[F]): Resource[F, ONode[F]] =
    Resource.pure[F, ONode[F]](new ONode[F] {

      def register(appId: Ident, nodeType: NodeType, uri: LenientUri): F[Unit] =
        for {
          node <- RNode(appId, nodeType, uri)
          _    <- logger.finfo(s"Registering node ${node.id.id}")
          _    <- store.transact(RNode.set(node))
        } yield ()

      def unregister(appId: Ident): F[Unit] =
        logger.finfo(s"Unregister app ${appId.id}") *>
          store.transact(RNode.delete(appId)).map(_ => ())
    })

}
