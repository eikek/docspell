package docspell.joex.process

import cats.effect._
import docspell.common.ProcessItemArgs
import docspell.analysis.TextAnalysisConfig
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
      .flatMap(analysisOnly[F](cfg.textAnalysis))
      .flatMap(Task.setProgress(75))
      .flatMap(LinkProposal[F])
      .flatMap(Task.setProgress(99))

  def analysisOnly[F[_]: Sync](
      cfg: TextAnalysisConfig
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    TextAnalysis[F](cfg)(item)
      .flatMap(FindProposal[F])
      .flatMap(EvalProposals[F])
      .flatMap(SaveProposals[F])

}
