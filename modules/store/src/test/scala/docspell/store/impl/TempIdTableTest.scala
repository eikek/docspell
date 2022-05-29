package docspell.store.impl

import cats.effect.IO
import docspell.common.Ident
import docspell.store._
import docspell.store.impl.TempIdTable.Row
import docspell.store.qb._
import docspell.store.qb.DSL._

class TempIdTableTest extends DatabaseTest {

  override def munitFixtures = postgresAll ++ mariaDbAll ++ h2All

  def id(str: String): Ident = Ident.unsafe(str)

  test("create temporary table postgres") {
    val store = pgStore()
    assertCreateTempTable(store)
  }

  test("create temporary table mariadb") {
    val store = mariaStore()
    assertCreateTempTable(store)
  }

  test("create temporary table h2") {
    val store = h2Store()
    assertCreateTempTable(store)
  }

  def assertCreateTempTable(store: Store[IO]) = {
    val insertRows = List(Row(id("abc-def")), Row(id("abc-123")), Row(id("zyx-321")))
    val create =
      for {
        table <- TempIdTable.createTable(store.dbms, "tt")
        n <- table.insertAll(insertRows)
        _ <- table.createIndex
        rows <- Select(select(table.all), from(table))
          .orderBy(table.id)
          .build
          .query[Row]
          .to[List]
      } yield (n, rows)

    val verify =
      store.transact(create).map { case (inserted, rows) =>
        if (store.dbms != Db.MariaDB) {
          assertEquals(inserted, 3)
        }
        assertEquals(rows, insertRows.sortBy(_.id))
      }

    verify *> verify
  }
}
