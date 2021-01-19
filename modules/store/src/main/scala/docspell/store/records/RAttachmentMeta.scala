package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RAttachmentMeta(
    id: Ident, //same as RAttachment.id
    content: Option[String],
    nerlabels: List[NerLabel],
    proposals: MetaProposalList,
    pages: Option[Int],
    language: Option[Language]
) {

  def setContentIfEmpty(txt: Option[String]): RAttachmentMeta =
    if (content.forall(_.trim.isEmpty)) copy(content = txt)
    else this

  def withPageCount(count: Option[Int]): RAttachmentMeta =
    copy(pages = count)
}

object RAttachmentMeta {
  def empty(attachId: Ident, lang: Language) =
    RAttachmentMeta(attachId, None, Nil, MetaProposalList.empty, None, Some(lang))

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "attachmentmeta"

    val id        = Column[Ident]("attachid", this)
    val content   = Column[String]("content", this)
    val nerlabels = Column[List[NerLabel]]("nerlabels", this)
    val proposals = Column[MetaProposalList]("itemproposals", this)
    val pages     = Column[Int]("page_count", this)
    val language  = Column[Language]("language", this)
    val all =
      NonEmptyList.of[Column[_]](
        id,
        content,
        nerlabels,
        proposals,
        pages,
        language
      )
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RAttachmentMeta): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.content},${v.nerlabels},${v.proposals},${v.pages},${v.language}"
    )

  def exists(attachId: Ident): ConnectionIO[Boolean] =
    Select(count(T.id).s, from(T), T.id === attachId).build.query[Int].unique.map(_ > 0)

  def findById(attachId: Ident): ConnectionIO[Option[RAttachmentMeta]] =
    run(select(T.all), from(T), T.id === attachId).query[RAttachmentMeta].option

  def findPageCountById(attachId: Ident): ConnectionIO[Option[Int]] =
    Select(T.pages.s, from(T), T.id === attachId).build
      .query[Option[Int]]
      .option
      .map(_.flatten)

  def upsert(v: RAttachmentMeta): ConnectionIO[Int] =
    for {
      n0 <- update(v)
      n1 <- if (n0 == 0) insert(v) else n0.pure[ConnectionIO]
    } yield n1

  def update(v: RAttachmentMeta): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === v.id,
      DML.set(
        T.content.setTo(v.content),
        T.nerlabels.setTo(v.nerlabels),
        T.proposals.setTo(v.proposals)
      )
    )

  def updateLabels(mid: Ident, labels: List[NerLabel]): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === mid,
      DML.set(
        T.nerlabels.setTo(labels)
      )
    )

  def updateProposals(
      mid: Ident,
      plist: MetaProposalList
  ): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === mid,
      DML.set(T.proposals.setTo(plist))
    )

  def updatePageCount(mid: Ident, pageCount: Option[Int]): ConnectionIO[Int] =
    DML.update(T, T.id === mid, DML.set(T.pages.setTo(pageCount)))

  def delete(attachId: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === attachId)
}
