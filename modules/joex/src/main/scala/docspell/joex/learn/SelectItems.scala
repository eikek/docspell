package docspell.joex.learn

import fs2.Stream

import docspell.analysis.classifier.TextClassifier.Data
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.store.Store
import docspell.store.qb.Batch
import docspell.store.queries.QItem

object SelectItems {
  val pageSep = LearnClassifierTask.pageSep
  val noClass = LearnClassifierTask.noClass

  def forCategory[F[_]](ctx: Context[F, _], collective: Ident)(
      max: Int,
      category: String
  ): Stream[F, Data] =
    forCategory(ctx.store, collective, max, category)

  def forCategory[F[_]](
      store: Store[F],
      collective: Ident,
      max: Int,
      category: String
  ): Stream[F, Data] = {
    val limit = if (max <= 0) Batch.all else Batch.limit(max)
    val connStream =
      for {
        item <- QItem.findAllNewesFirst(collective, 10, limit)
        tt <- Stream.eval(
          QItem.resolveTextAndTag(collective, item, category, pageSep)
        )
      } yield Data(tt.tag.map(_.name).getOrElse(noClass), item.id, tt.text.trim)
    store.transact(connStream.filter(_.text.nonEmpty))
  }

}
