/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect.{Async, Resource}
import cats.implicits._

import docspell.common.{AccountId, Ident}
import docspell.store.UpdateResult
import docspell.store.records.RSource
import docspell.store.records.SourceData
import docspell.store.{AddResult, Store}

trait OSource[F[_]] {

  def findAll(account: AccountId): F[Vector[SourceData]]

  def add(s: RSource, tags: List[String]): F[AddResult]

  def update(s: RSource, tags: List[String]): F[AddResult]

  def delete(id: Ident, collective: Ident): F[UpdateResult]
}

object OSource {

  def apply[F[_]: Async](store: Store[F]): Resource[F, OSource[F]] =
    Resource.pure[F, OSource[F]](new OSource[F] {
      def findAll(account: AccountId): F[Vector[SourceData]] =
        store
          .transact(SourceData.findAll(account.collective, _.abbrev))
          .compile
          .to(Vector)

      def add(s: RSource, tags: List[String]): F[AddResult] = {
        def insert = SourceData.insert(s, tags)
        def exists = RSource.existsByAbbrev(s.cid, s.abbrev)

        val msg = s"A source with abbrev '${s.abbrev}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def update(s: RSource, tags: List[String]): F[AddResult] = {
        def insert = SourceData.update(s, tags)
        def exists = RSource.existsByAbbrev(s.cid, s.abbrev)

        val msg = s"A source with abbrev '${s.abbrev}' already exists"
        store.add(insert, exists).map(_.fold(identity, _.withMsg(msg), identity))
      }

      def delete(id: Ident, collective: Ident): F[UpdateResult] =
        UpdateResult.fromUpdate(store.transact(SourceData.delete(id, collective)))

    })
}
