package docspell.joex.process

import cats.implicits._
import cats.effect.Sync
import docspell.common.{Duration, Language, NerLabel, ProcessItemArgs}
import docspell.joex.process.ItemData.AttachmentDates
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachmentMeta
import docspell.text.contact.Contact
import docspell.text.date.DateFind
import docspell.text.nlp.StanfordNerClassifier

object TextAnalysis {

  def apply[F[_]: Sync](item: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _  <- ctx.logger.info("Starting text analysis")
        s  <- Duration.stopTime[F]
        t  <- item.metas.toList.traverse(annotateAttachment[F](ctx.args.meta.language))
        _  <- ctx.logger.debug(s"Storing tags: ${t.map(_._1.copy(content = None))}")
        _  <- t.traverse(m => ctx.store.transact(RAttachmentMeta.updateLabels(m._1.id, m._1.nerlabels)))
        e  <- s
        _  <- ctx.logger.info(s"Text-Analysis finished in ${e.formatExact}")
        v   = t.toVector
      } yield item.copy(metas = v.map(_._1), dateLabels = v.map(_._2))
    }

  def annotateAttachment[F[_]: Sync](lang: Language)(rm: RAttachmentMeta): F[(RAttachmentMeta, AttachmentDates)] =
    for {
      list0 <- stanfordNer[F](lang, rm)
      list1 <- contactNer[F](rm)
      dates <- dateNer[F](rm, lang)
    } yield (rm.copy(nerlabels = (list0 ++ list1 ++ dates.toNerLabel).toList), dates)

  def stanfordNer[F[_]: Sync](lang: Language, rm: RAttachmentMeta): F[Vector[NerLabel]] = Sync[F].delay {
    rm.content.map(StanfordNerClassifier.nerAnnotate(lang)).getOrElse(Vector.empty)
  }

  def contactNer[F[_]: Sync](rm: RAttachmentMeta): F[Vector[NerLabel]] = Sync[F].delay {
    rm.content.map(Contact.annotate).getOrElse(Vector.empty)
  }

  def dateNer[F[_]: Sync](rm: RAttachmentMeta, lang: Language): F[AttachmentDates] = Sync[F].delay {
    AttachmentDates(rm, rm.content.map(txt => DateFind.findDates(txt, lang).toVector).getOrElse(Vector.empty))
  }


}
