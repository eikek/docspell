package docspell.joex

import cats.effect._

final class JoexAppImpl[F[_]: Sync](cfg: Config) extends JoexApp[F] {

  def init: F[Unit] =
    Sync[F].pure(())

}

object JoexAppImpl {

  def create[F[_]: Sync](cfg: Config): Resource[F, JoexApp[F]] =
    Resource.liftF(Sync[F].pure(new JoexAppImpl(cfg)))
}
