/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import cats.effect._
import cats.syntax.all._

import docspell.ftsclient.{FtsQuery, TextData}
import docspell.logging.{Level, LogConfig, TestLoggingConfig}

import com.dimafeng.testcontainers.PostgreSQLContainer
import com.dimafeng.testcontainers.munit.TestContainerForAll
import doobie.implicits._
import munit.CatsEffectSuite
import org.testcontainers.utility.DockerImageName

class PsqlFtsClientTest
    extends CatsEffectSuite
    with PgFixtures
    with TestContainerForAll
    with TestLoggingConfig {
  override val containerDef: PostgreSQLContainer.Def =
    PostgreSQLContainer.Def(DockerImageName.parse("postgres:14"))

  val logger = docspell.logging.getLogger[IO]

  private val table = FtsRepository.table

  override def docspellLogConfig: LogConfig =
    super.docspellLogConfig.docspellLevel(Level.Debug)

  test("insert data into index") {
    withContainers { cnt =>
      psqlFtsClient(cnt).use { implicit client =>
        def assertions(id: TextData.Item, ad: TextData.Attachment) =
          for {
            n <- sql"SELECT count(*) from $table".query[Int].unique.exec
            _ = assertEquals(n, 2)
            itemStored <-
              sql"select item_name, item_notes from $table WHERE id = ${id.id}"
                .query[(Option[String], Option[String])]
                .unique
                .exec
            _ = assertEquals(itemStored, (id.name, id.notes))
            attachStored <-
              sql"select attach_name, attach_content from $table where id = ${ad.id}"
                .query[(Option[String], Option[String])]
                .unique
                .exec
            _ = assertEquals(attachStored, (ad.name, ad.text))
          } yield ()

        for {
          _ <- client.indexData(logger, itemData, attachData)
          _ <- assertions(itemData, attachData)
          _ <- client.indexData(logger, itemData, attachData)
          _ <- assertions(itemData, attachData)

          _ <- client.indexData(
            logger,
            itemData.copy(notes = None),
            attachData.copy(name = "ha.pdf".some)
          )
          _ <- assertions(
            itemData.copy(notes = None),
            attachData.copy(name = "ha.pdf".some)
          )
        } yield ()
      }
    }
  }

  test("clear index") {
    withContainers { cnt =>
      psqlFtsClient(cnt).use { implicit client =>
        for {
          _ <- client.indexData(logger, itemData, attachData)
          _ <- client.clearAll(logger)
          n <- sql"select count(*) from $table".query[Int].unique.exec
          _ = assertEquals(n, 0)
        } yield ()
      }
    }
  }

  test("clear index by collective") {
    withContainers { cnt =>
      psqlFtsClient(cnt).use { implicit client =>
        for {
          _ <- client.indexData(
            logger,
            itemData,
            attachData,
            itemData.copy(collective = collective2, item = ident("item-id-2")),
            attachData.copy(collective = collective2, item = ident("item-id-2"))
          )
          n <- sql"select count(*) from $table".query[Int].unique.exec
          _ = assertEquals(n, 4)

          _ <- client.clear(logger, collective1)
          n <- sql"select count(*) from $table".query[Int].unique.exec
          _ = assertEquals(n, 2)
        } yield ()
      }
    }
  }

  test("search by query") {
    def query(s: String): FtsQuery =
      FtsQuery(
        q = s,
        collective = collective1,
        items = Set.empty,
        folders = Set.empty,
        limit = 10,
        offset = 0,
        highlight = FtsQuery.HighlightSetting.default
      )

    withContainers { cnt =>
      psqlFtsClient(cnt).use { implicit client =>
        for {
          _ <- client.indexData(
            logger,
            itemData,
            attachData,
            itemData.copy(collective = collective2, item = ident("item-id-2")),
            attachData.copy(collective = collective2, item = ident("item-id-2"))
          )

          res0 <- client.search(query("lorem uiaeduiae"))
          _ = assertEquals(res0.count, 0)

          res1 <- client.search(query("lorem"))
          _ = assertEquals(res1.count, 1)
          _ = assertEquals(res1.results.head.id, attachData.id)

          res2 <- client.search(query("note"))
          _ = assertEquals(res2.count, 1)
          _ = assertEquals(res2.results.head.id, itemData.id)
        } yield ()
      }
    }
  }
}
