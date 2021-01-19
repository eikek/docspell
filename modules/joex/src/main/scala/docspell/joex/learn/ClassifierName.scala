package docspell.joex.learn

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common.Ident
import docspell.store.records.{RClassifierModel, RClassifierSetting}

import doobie._

final class ClassifierName(val name: String) extends AnyVal

object ClassifierName {
  def apply(name: String): ClassifierName =
    new ClassifierName(name)

  private val categoryPrefix = "tagcategory-"

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
      categories <- RClassifierSetting.getActiveCategories(coll)
      models <- NonEmptyList.fromList(categories) match {
        case Some(nel) =>
          RClassifierModel.findAllByName(coll, nel.map(tagCategory).map(_.name))
        case None =>
          List.empty[RClassifierModel].pure[ConnectionIO]
      }
    } yield models

  def findOrphanTagModels[F[_]](coll: Ident): ConnectionIO[List[RClassifierModel]] =
    for {
      cats <- RClassifierSetting.getActiveCategories(coll)
      allModels = RClassifierModel.findAllByQuery(coll, s"${categoryPrefix}%")
      result <- NonEmptyList.fromList(cats) match {
        case Some(nel) =>
          allModels.flatMap(all =>
            RClassifierModel
              .findAllByName(coll, nel.map(tagCategory).map(_.name))
              .map(active => all.diff(active))
          )
        case None =>
          allModels
      }
    } yield result

}
