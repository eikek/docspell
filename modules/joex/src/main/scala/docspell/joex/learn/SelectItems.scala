package docspell.joex.learn

import fs2.{Pipe, Stream}

import docspell.analysis.classifier.TextClassifier.Data
import docspell.common._
import docspell.joex.scheduler.Context
import docspell.store.Store
import docspell.store.qb.Batch
import docspell.store.queries.{QItem, TextAndTag}

import doobie._

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
    val connStream =
      allItems(collective, max)
        .evalMap(item => QItem.resolveTextAndTag(collective, item, category, pageSep))
        .through(mkData)
    store.transact(connStream)
  }

  def forCorrOrg[F[_]](
      store: Store[F],
      collective: Ident,
      max: Int
  ): Stream[F, Data] = {
    val connStream =
      allItems(collective, max)
        .evalMap(item => QItem.resolveTextAndCorrOrg(collective, item, pageSep))
        .through(mkData)
    store.transact(connStream)
  }

  def forCorrPerson[F[_]](
      store: Store[F],
      collective: Ident,
      max: Int
  ): Stream[F, Data] = {
    val connStream =
      allItems(collective, max)
        .evalMap(item => QItem.resolveTextAndCorrPerson(collective, item, pageSep))
        .through(mkData)
    store.transact(connStream)
  }

  def forConcPerson[F[_]](
      store: Store[F],
      collective: Ident,
      max: Int
  ): Stream[F, Data] = {
    val connStream =
      allItems(collective, max)
        .evalMap(item => QItem.resolveTextAndConcPerson(collective, item, pageSep))
        .through(mkData)
    store.transact(connStream)
  }

  def forConcEquip[F[_]](
      store: Store[F],
      collective: Ident,
      max: Int
  ): Stream[F, Data] = {
    val connStream =
      allItems(collective, max)
        .evalMap(item => QItem.resolveTextAndConcEquip(collective, item, pageSep))
        .through(mkData)
    store.transact(connStream)
  }

  private def allItems(collective: Ident, max: Int): Stream[ConnectionIO, Ident] = {
    val limit = if (max <= 0) Batch.all else Batch.limit(max)
    QItem.findAllNewesFirst(collective, 10, limit)
  }

  private def mkData[F[_]]: Pipe[F, TextAndTag, Data] =
    _.map(tt => Data(tt.tag.map(_.name).getOrElse(noClass), tt.itemId.id, tt.text.trim))
      .filter(_.text.nonEmpty)
}
