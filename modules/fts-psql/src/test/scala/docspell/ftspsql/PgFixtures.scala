/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import javax.sql.DataSource

import cats.effect._
import cats.syntax.all._

import docspell.common._
import docspell.ftsclient.TextData
import docspell.store.{JdbcConfig, StoreFixture}

import com.dimafeng.testcontainers.PostgreSQLContainer
import doobie._
import doobie.implicits._

trait PgFixtures {
  def ident(n: String): Ident = Ident.unsafe(n)

  def psqlConfig(cnt: PostgreSQLContainer): PsqlConfig =
    PsqlConfig.defaults(
      LenientUri.unsafe(cnt.jdbcUrl),
      cnt.username,
      Password(cnt.password)
    )

  def jdbcConfig(cnt: PostgreSQLContainer): JdbcConfig =
    JdbcConfig(LenientUri.unsafe(cnt.jdbcUrl), cnt.username, cnt.password)

  def dataSource(cnt: PostgreSQLContainer): Resource[IO, DataSource] =
    StoreFixture.dataSource(jdbcConfig(cnt))

  def transactor(cnt: PostgreSQLContainer): Resource[IO, Transactor[IO]] =
    dataSource(cnt).flatMap(StoreFixture.makeXA)

  def psqlFtsClient(cnt: PostgreSQLContainer): Resource[IO, PsqlFtsClient[IO]] =
    transactor(cnt)
      .map(xa => PsqlFtsClient.fromTransactor(psqlConfig(cnt), xa))
      .evalTap(client => DbMigration[IO](client.config).run)

  def runQuery[A](cnt: PostgreSQLContainer)(q: ConnectionIO[A]): IO[A] =
    transactor(cnt).use(q.transact(_))

  implicit class QueryOps[A](self: ConnectionIO[A]) {
    def exec(implicit client: PsqlFtsClient[IO]): IO[A] =
      self.transact(client.transactor)
  }

  val collective1 = ident("coll1")
  val collective2 = ident("coll2")

  val itemData: TextData.Item =
    TextData.Item(
      item = ident("item-id-1"),
      collective = collective1,
      folder = None,
      name = "mydoc.pdf".some,
      notes = Some("my notes are these"),
      language = Language.English
    )

  val attachData: TextData.Attachment =
    TextData.Attachment(
      item = ident("item-id-1"),
      attachId = ident("attach-id-1"),
      collective = collective1,
      folder = None,
      language = Language.English,
      name = "mydoc.pdf".some,
      text = "lorem ipsum dolores est".some
    )
}
