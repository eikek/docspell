package docspell.convert.extern

import cats.effect._
import fs2.Pipe
import docspell.common._

object Unoconv {

  def toPDF[F[_]: Sync: ContextShift](
      cfg: UnoconvConfig,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F],
  ): Pipe[F, Byte, Byte] =
    ExternConv.toPDF[F]("unoconv", cfg.cmd, cfg.workingDir, chunkSize, false, blocker, logger)


}
