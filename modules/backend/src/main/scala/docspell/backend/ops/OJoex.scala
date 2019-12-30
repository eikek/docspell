package docspell.backend.ops

import cats.implicits._
import cats.effect.ConcurrentEffect
import docspell.common.{Ident, NodeType}
import docspell.store.Store
import docspell.store.records.RNode
import org.http4s.client.blaze.BlazeClientBuilder
import org.http4s.Method._
import org.http4s.{Request, Uri}

import scala.concurrent.ExecutionContext
import org.log4s._

object OJoex {
  private[this] val logger = getLogger

  def notifyAll[F[_]: ConcurrentEffect](
      store: Store[F],
      clientExecutionContext: ExecutionContext
  ): F[Unit] =
    for {
      nodes <- store.transact(RNode.findAll(NodeType.Joex))
      _     <- nodes.toList.traverse(notifyJoex[F](clientExecutionContext))
    } yield ()

  def cancelJob[F[_]: ConcurrentEffect](
      jobId: Ident,
      worker: Ident,
      store: Store[F],
      clientEc: ExecutionContext
  ): F[Boolean] =
    for {
      node   <- store.transact(RNode.findById(worker))
      cancel <- node.traverse(joexCancel(clientEc)(_, jobId))
    } yield cancel.getOrElse(false)

  private def joexCancel[F[_]: ConcurrentEffect](
      ec: ExecutionContext
  )(node: RNode, job: Ident): F[Boolean] = {
    val notifyUrl = node.url / "api" / "v1" / "job" / job.id / "cancel"
    BlazeClientBuilder[F](ec).resource.use { client =>
      val req = Request[F](POST, Uri.unsafeFromString(notifyUrl.asString))
      client.expect[String](req).map(_ => true)
    }
  }

  private def notifyJoex[F[_]: ConcurrentEffect](ec: ExecutionContext)(node: RNode): F[Unit] = {
    val notifyUrl = node.url / "api" / "v1" / "notify"
    val execute = BlazeClientBuilder[F](ec).resource.use { client =>
      val req = Request[F](POST, Uri.unsafeFromString(notifyUrl.asString))
      client.expect[String](req).map(_ => ())
    }
    execute.attempt.map {
      case Right(_) =>
        ()
      case Left(_) =>
        logger.warn(s"Notifying Joex instance '${node.id.id}/${node.url.asString}' failed.")
        ()
    }
  }
}
