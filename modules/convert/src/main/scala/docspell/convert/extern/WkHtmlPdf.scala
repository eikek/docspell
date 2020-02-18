package docspell.convert.extern

import cats.effect._
import fs2.Pipe
import docspell.common._

object WkHtmlPdf {

  def toPDF[F[_]: Sync: ContextShift](
      cfg: WkHtmlPdfConfig,
      chunkSize: Int,
      blocker: Blocker,
      logger: Logger[F],
  ): Pipe[F, Byte, Byte] =
    ExternConv.toPDF[F]("wkhtmltopdf", cfg.cmd, cfg.workingDir, chunkSize, true, blocker, logger)


}
