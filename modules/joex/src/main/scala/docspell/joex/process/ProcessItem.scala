package docspell.joex.process

import cats.effect._
import docspell.common.ProcessItemArgs
import docspell.joex.scheduler.Task
import docspell.joex.Config
import docspell.ftsclient.FtsClient

object ProcessItem {

  def apply[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config,
      fts: FtsClient[F]
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    ExtractArchive(item)
      .flatMap(Task.setProgress(20))
      .flatMap(ConvertPdf(cfg.convert, _))
      .flatMap(Task.setProgress(40))
      .flatMap(TextExtraction(cfg.extraction, fts))
      .flatMap(Task.setProgress(60))
      .flatMap(analysisOnly[F](cfg))
      .flatMap(Task.setProgress(80))
      .flatMap(LinkProposal[F])
      .flatMap(Task.setProgress(99))

  def analysisOnly[F[_]: Sync](
      cfg: Config
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    TextAnalysis[F](cfg.textAnalysis)(item)
      .flatMap(FindProposal[F](cfg.processing))
      .flatMap(EvalProposals[F])
      .flatMap(SaveProposals[F])
}
