package docspell.scheduler

import cats.Applicative
import docspell.common.AccountInfo

/** Strategy to find the user that submitted the job. This is used to emit events about
  * starting/finishing jobs.
  *
  * If an account cannot be determined, no events can be send.
  */
trait FindJobOwner[F[_]] {
  def apply(job: Job[_]): F[Option[AccountInfo]]
}

object FindJobOwner {

  def none[F[_]: Applicative]: FindJobOwner[F] =
    (_: Job[_]) => Applicative[F].pure(None)
}
