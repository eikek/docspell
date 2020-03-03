package docspell.backend.ops

import cats.implicits._
import cats.effect._
import docspell.common.{Ident, NodeType}
import docspell.joexapi.client.JoexClient
import docspell.store.Store
import docspell.store.records.RNode

import scala.concurrent.ExecutionContext

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
        for {
          node   <- store.transact(RNode.findById(worker))
          cancel <- node.traverse(n => client.cancelJob(n.url, job))
        } yield cancel.isDefined
    })

  def create[F[_]: ConcurrentEffect](ec: ExecutionContext, store: Store[F]): Resource[F, OJoex[F]] =
    JoexClient.resource(ec).flatMap(client => apply(client, store))

}
