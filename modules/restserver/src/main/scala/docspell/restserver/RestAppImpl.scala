package docspell.restserver

import scala.concurrent.ExecutionContext

import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.common.NodeType
import docspell.ftsclient.FtsClient
import docspell.ftssolr.SolrFtsClient

import org.http4s.client.Client

final class RestAppImpl[F[_]](val config: Config, val backend: BackendApp[F])
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
      backend <- BackendApp(cfg.backend, connectEC, httpClientEc, blocker)(
        createFtsClient[F](cfg)
      )
      app = new RestAppImpl[F](cfg, backend)
      appR <- Resource.make(app.init.map(_ => app))(_.shutdown)
    } yield appR

  private def createFtsClient[F[_]: ConcurrentEffect](
      cfg: Config
  )(client: Client[F]): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled) SolrFtsClient(cfg.fullTextSearch.solr, client)
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])
}
