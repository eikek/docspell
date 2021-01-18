package docspell.joex.learn

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common.Ident
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records.{RClassifierModel, RTag}

import doobie._

final class ClassifierName(val name: String) extends AnyVal

object ClassifierName {
  def apply(name: String): ClassifierName =
    new ClassifierName(name)

  val categoryPrefix = "tagcategory-"

  def tagCategory(cat: String): ClassifierName =
    apply(s"${categoryPrefix}${cat}")

  val concernedPerson: ClassifierName =
    apply("concernedperson")

  val concernedEquip: ClassifierName =
    apply("concernedequip")

  val correspondentOrg: ClassifierName =
    apply("correspondentorg")

  val correspondentPerson: ClassifierName =
    apply("correspondentperson")

  def findTagModels[F[_]](coll: Ident): ConnectionIO[List[RClassifierModel]] =
    for {
      categories <- RTag.listCategories(coll)
      models <- NonEmptyList.fromList(categories) match {
        case Some(nel) =>
          RClassifierModel.findAllByName(coll, nel.map(tagCategory).map(_.name))
        case None =>
          List.empty[RClassifierModel].pure[ConnectionIO]
      }
    } yield models

  def findOrphanTagModels[F[_]](coll: Ident): ConnectionIO[List[RClassifierModel]] = {
    val model = RClassifierModel.as("m")
    val tag   = RTag.as("t")
    val sql =
      Select(
        select(model.all),
        from(model),
        model.cid === coll && model.name.notIn(
          Select(
            select(concat(lit(categoryPrefix), tag.category.s)),
            from(tag),
            tag.cid === coll && tag.category.isNotNull
          ).distinct
        )
      ).build
    sql.query[RClassifierModel].to[List]
  }

}
