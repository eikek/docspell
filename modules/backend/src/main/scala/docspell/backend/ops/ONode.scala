/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.{Ident, LenientUri, NodeType}
import docspell.store.Store
import docspell.store.records.RNode

trait ONode[F[_]] {

  def register(appId: Ident, nodeType: NodeType, uri: LenientUri): F[Unit]

  def unregister(appId: Ident): F[Unit]
}

object ONode {

  def apply[F[_]: Async](store: Store[F]): Resource[F, ONode[F]] =
    Resource.pure[F, ONode[F]](new ONode[F] {
      val logger = docspell.logging.getLogger[F]
      def register(appId: Ident, nodeType: NodeType, uri: LenientUri): F[Unit] =
        for {
          node <- RNode(appId, nodeType, uri)
          _ <- logger.info(s"Registering node ${node.id.id}")
          _ <- store.transact(RNode.set(node))
        } yield ()

      def unregister(appId: Ident): F[Unit] =
        logger.info(s"Unregister app ${appId.id}") *>
          store.transact(RNode.delete(appId)).map(_ => ())
    })

}
