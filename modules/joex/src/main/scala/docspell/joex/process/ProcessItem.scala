package docspell.joex.process

import cats.effect._
import docspell.common.ProcessItemArgs
import docspell.joex.scheduler.Task
import docspell.joex.Config

object ProcessItem {

  def apply[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    ExtractArchive(item)
      .flatMap(ConvertPdf(cfg.convert, _))
      .flatMap(TextExtraction(cfg.extraction, _))
      .flatMap(Task.setProgress(50))
      .flatMap(analysisOnly[F])
      .flatMap(Task.setProgress(75))
      .flatMap(LinkProposal[F])
      .flatMap(Task.setProgress(99))

  def analysisOnly[F[_]: Sync](item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    TextAnalysis[F](item)
      .flatMap(FindProposal[F])
      .flatMap(EvalProposals[F])
      .flatMap(SaveProposals[F])

}
