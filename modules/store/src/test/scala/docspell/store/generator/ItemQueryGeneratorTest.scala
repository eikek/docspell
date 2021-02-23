package docspell.store.generator

import java.time.LocalDate

import docspell.store.records._
import minitest._
import docspell.common._
import docspell.query.ItemQueryParser
import docspell.store.qb.DSL._
import docspell.store.qb.generator.{ItemQueryGenerator, Tables}

object ItemQueryGeneratorTest extends SimpleTestSuite {
  import docspell.store.impl.DoobieMeta._

  val tables = Tables(
    RItem.as("i"),
    ROrganization.as("co"),
    RPerson.as("cp"),
    RPerson.as("np"),
    REquipment.as("ne"),
    RFolder.as("f"),
    RAttachment.as("a"),
    RAttachmentMeta.as("m")
  )

  test("migration") {
    val q = ItemQueryParser
      .parseUnsafe("(& name:hello date>=2020-02-01 (| source=expense folder=test ))")
    val cond = ItemQueryGenerator(tables, Ident.unsafe("coll"))(q)
    val expect =
      tables.item.name.like("hello") && tables.item.itemDate >= Timestamp.atUtc(
        LocalDate.of(2020, 2, 1).atStartOfDay()
      ) && (tables.item.source === "expense" || tables.folder.name === "test")

    assertEquals(cond, expect)
  }

//  test("migration2") {
//    withStore("db2") { store =>
//      val c = RCollective(
//        Ident.unsafe("coll1"),
//        CollectiveState.Active,
//        Language.German,
//        true,
//        Timestamp.Epoch
//      )
//      val e =
//        REquipment(
//          Ident.unsafe("equip"),
//          Ident.unsafe("coll1"),
//          "name",
//          Timestamp.Epoch,
//          Timestamp.Epoch,
//          None
//        )
//
//      for {
//        _ <- store.transact(RCollective.insert(c))
//        _ <- store.transact(REquipment.insert(e)).map(_ => ())
//      } yield ()
//    }
//  }
}
