package docspell.store.qb.impl

import minitest._
import docspell.store.qb._
import docspell.store.qb.DSL._
import docspell.store.qb.model.{CourseRecord, PersonRecord}

object ConditionBuilderTest extends SimpleTestSuite {

  val c = CourseRecord.as("c")
  val p = PersonRecord.as("p")

  test("reduce ands") {
    val cond =
      c.lessons > 3 && (c.id === 5L && (p.name === "john" && Condition.unit && p.id === 1L))
    val expected =
      and(c.lessons > 3, c.id === 5L, p.name === "john", p.id === 1L)

    assertEquals(ConditionBuilder.reduce(cond), expected)
    assertEquals(ConditionBuilder.reduce(expected), expected)
  }

  test("reduce ors") {
    val cond =
      c.lessons > 3 || (c.id === 5L || (p.name === "john" || Condition.unit || p.id === 1L))
    val expected =
      or(c.lessons > 3, c.id === 5L, p.name === "john", p.id === 1L)

    assertEquals(ConditionBuilder.reduce(cond), expected)
    assertEquals(ConditionBuilder.reduce(expected), expected)
  }

  test("mixed and / or") {
    val cond = c.lessons > 3 && (p.name === "john" || p.name === "mara") && c.id > 3
    val expected =
      and(c.lessons > 3, or(p.name === "john", p.name === "mara"), c.id > 3)
    assertEquals(ConditionBuilder.reduce(cond), expected)
    assertEquals(ConditionBuilder.reduce(expected), expected)
  }

  test("reduce double not") {
    val cond = Condition.Not(Condition.Not(c.name === "scala"))
    assertEquals(ConditionBuilder.reduce(cond), c.name === "scala")
  }

  test("reduce triple not") {
    val cond = Condition.Not(Condition.Not(Condition.Not(c.name === "scala")))
    assertEquals(ConditionBuilder.reduce(cond), not(c.name === "scala"))
  }

  test("reduce not to unit") {
    val cond = Condition.Not(Condition.Not(Condition.Not(Condition.Not(Condition.unit))))
    assertEquals(ConditionBuilder.reduce(cond), Condition.unit)
  }

  test("remove units in and/or") {
    val cond =
      c.name === "scala" && Condition.unit && (c.name === "fp" || Condition.unit) && Condition.unit
    assertEquals(ConditionBuilder.reduce(cond), and(c.name === "scala", c.name === "fp"))
  }

  test("unwrap single and/ors") {
    assertEquals(
      ConditionBuilder.reduce(Condition.Or(c.name === "scala")),
      c.name === "scala"
    )
    assertEquals(
      ConditionBuilder.reduce(Condition.And(c.name === "scala")),
      c.name === "scala"
    )

    assertEquals(
      ConditionBuilder.reduce(Condition.unit && c.name === "scala" && Condition.unit),
      c.name === "scala"
    )
    assertEquals(
      ConditionBuilder.reduce(Condition.unit || c.name === "scala" || Condition.unit),
      c.name === "scala"
    )

    assertEquals(
      ConditionBuilder.reduce(and(and(and(c.name === "scala"), Condition.unit))),
      c.name === "scala"
    )
  }

  test("reduce empty and/or") {
    assertEquals(
      ConditionBuilder.reduce(Condition.unit && Condition.unit && Condition.unit),
      Condition.unit
    )
    assertEquals(
      ConditionBuilder.reduce(Condition.unit || Condition.unit || Condition.unit),
      Condition.unit
    )
  }
}
