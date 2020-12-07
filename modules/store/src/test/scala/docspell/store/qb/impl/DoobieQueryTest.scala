package docspell.store.qb.impl

import minitest._
import docspell.store.qb._
import docspell.store.qb.model._
import docspell.store.qb.DSL._
import docspell.common._

object DoobieQueryTest extends SimpleTestSuite {

  test("basic fragment") {
    val c        = CourseRecord.as("c")
    val owner    = PersonRecord.as("o")
    val lecturer = PersonRecord.as("l")

    val proj = select(c.all)
    val table = from(c)
      .innerJoin(owner, c.ownerId === owner.id)
      .leftJoin(lecturer, c.lecturerId === lecturer.id)
    val cond = where(
      c.name.like("%test%"),
      owner.name === "Harald"
    )

    val q    = Select(proj, table, cond)
    val frag = DoobieQuery.select(q)
    assertEquals(
      frag.toString,
      """Fragment("SELECT c.id, c.name, c.owner_id, c.lecturer_id, c.lessons FROM course c INNER JOIN person o ON c.owner_id = o.id LEFT JOIN person l ON c.lecturer_id = l.id WHERE (LOWER(c.name) LIKE ? AND o.name = ? )")"""
    )
  }

  test("basic update") {
    val p = PersonRecord.table

    val update = PersonRecord.update(p.name.set("john"), p.id.set(15L)).where(p.id >= 2)

    println(DoobieQuery.update(update))

  }

  test("basic insert") {
    val p = PersonRecord(1, "John", Timestamp.Epoch)

    val insert = PersonRecord.insertAll(p)

    println(insert)

  }
}
