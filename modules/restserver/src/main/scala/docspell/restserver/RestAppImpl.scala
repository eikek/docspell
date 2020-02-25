package docspell.restserver

import cats.implicits._
import cats.effect._
import docspell.backend.BackendApp
import docspell.common.NodeType

import scala.concurrent.ExecutionContext

final class RestAppImpl[F[_]: Sync](val config: Config, val backend: BackendApp[F])
    extends RestApp[F] {

  def init: F[Unit] =
    backend.node.register(config.appId, NodeType.Restserver, config.baseUrl)

  def shutdown: F[Unit] =
    backend.node.unregister(config.appId)
}

object RestAppImpl {

  def create[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config,
      connectEC: ExecutionContext,
      httpClientEc: ExecutionContext,
      blocker: Blocker
  ): Resource[F, RestApp[F]] =
    for {
      backend <- BackendApp(cfg.backend, connectEC, httpClientEc, blocker)
      app = new RestAppImpl[F](cfg, backend)
      appR <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR

}
