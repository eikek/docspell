package docspell.store.ops

import cats.effect.{Effect, Resource}
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

  def apply[F[_] : Effect](store: Store[F]): Resource[F, ONode[F]] =
    Resource.pure(new ONode[F] {

      def register(appId: Ident, nodeType: NodeType, uri: LenientUri): F[Unit] =
        for {
          node <- RNode(appId, nodeType, uri)
          _    <- logger.finfo(s"Registering node $node")
          _    <- store.transact(RNode.set(node))
        } yield ()

      def unregister(appId: Ident): F[Unit] =
        logger.finfo(s"Unregister app ${appId.id}") *>
          store.transact(RNode.delete(appId)).map(_ => ())
    })

}
