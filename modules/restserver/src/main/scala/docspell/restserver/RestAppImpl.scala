package docspell.restserver

import cats.effect._

final class RestAppImpl[F[_]: Sync](cfg: Config) extends RestApp[F] {

  def init: F[Unit] =
    Sync[F].pure(())

}

object RestAppImpl {

  def create[F[_]: Sync](cfg: Config): Resource[F, RestApp[F]] =
    Resource.liftF(Sync[F].pure(new RestAppImpl(cfg)))
}
