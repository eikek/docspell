package docspell.store.qb

import minitest._
import docspell.store.qb.model._
import docspell.store.qb.DSL._

object QueryBuilderTest extends SimpleTestSuite {

  test("simple") {
    val c        = CourseRecord.as("c")
    val owner    = PersonRecord.as("p1")
    val lecturer = PersonRecord.as("p2")

    val proj = select(c.all, owner.all, lecturer.all)

    val tables =
      from(c)
        .innerJoin(owner, c.ownerId === owner.id)
        .leftJoin(lecturer, c.lecturerId === lecturer.id)

    val cond =
      where(
        c.name.like("%scala%"),
        c.lessons <= 15,
        or(
          owner.name.like("%"),
          lecturer.id >= 1
        )
      )

    // val order =
    //   orderBy(c.name.asc)

    val q = Select(proj, tables, cond)
    println(q)
  }
}
