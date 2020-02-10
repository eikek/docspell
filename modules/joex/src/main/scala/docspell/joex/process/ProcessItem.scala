package docspell.joex.process

import cats.effect.{ContextShift, Sync}
import docspell.common.ProcessItemArgs
import docspell.joex.scheduler.Task
import docspell.joex.Config

object ProcessItem {

  def apply[F[_]: Sync: ContextShift](
      cfg: Config
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    ConvertPdf(cfg.convert, item)
      .flatMap(TextExtraction(cfg.extraction, _))
      .flatMap(Task.setProgress(25))
      .flatMap(TextAnalysis[F])
      .flatMap(Task.setProgress(50))
      .flatMap(FindProposal[F])
      .flatMap(Task.setProgress(75))
      .flatMap(LinkProposal[F])
      .flatMap(Task.setProgress(99))
}
