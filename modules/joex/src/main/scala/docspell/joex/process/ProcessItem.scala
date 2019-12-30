package docspell.joex.process

import cats.effect.{ContextShift, Sync}
import docspell.common.ProcessItemArgs
import docspell.joex.scheduler.Task
import docspell.text.ocr.{Config => OcrConfig}

object ProcessItem {

  def apply[F[_]: Sync: ContextShift](
      cfg: OcrConfig
  )(item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    TextExtraction(cfg, item)
      .flatMap(Task.setProgress(25))
      .flatMap(TextAnalysis[F])
      .flatMap(Task.setProgress(50))
      .flatMap(FindProposal[F])
      .flatMap(Task.setProgress(75))
      .flatMap(LinkProposal[F])
      .flatMap(Task.setProgress(99))
}
