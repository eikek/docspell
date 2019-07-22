package docspell.store.records

import cats.implicits._
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

case class RAttachmentMeta(id: Ident
                           , content: Option[String]
                           , nerlabels: List[NerLabel]
                           , proposals: MetaProposalList) {

}

object RAttachmentMeta {
  def empty(attachId: Ident) = RAttachmentMeta(attachId, None, Nil, MetaProposalList.empty)

  val table = fr"attachmentmeta"

  object Columns {
    val id = Column("attachid")
    val content = Column("content")
    val nerlabels = Column("nerlabels")
    val proposals = Column("itemproposals")
    val all = List(id, content, nerlabels, proposals)
  }
  import Columns._

  def insert(v: RAttachmentMeta): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.id},${v.content},${v.nerlabels},${v.proposals}").update.run

  def exists(attachId: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, id is attachId).query[Int].unique.map(_ > 0)

  def upsert(v: RAttachmentMeta): ConnectionIO[Int] =
    for {
      n0  <- update(v)
      n1  <- if (n0 == 0) insert(v) else n0.pure[ConnectionIO]
    } yield n1

  def update(v: RAttachmentMeta): ConnectionIO[Int] =
    updateRow(table, id is v.id, commas(
      content setTo v.content,
      nerlabels setTo v.nerlabels,
      proposals setTo v.proposals
    )).update.run

  def updateLabels(mid: Ident, labels: List[NerLabel]): ConnectionIO[Int] =
    updateRow(table, id is mid, commas(
      nerlabels setTo labels
    )).update.run

  def updateProposals(mid: Ident, plist: MetaProposalList): ConnectionIO[Int] =
    updateRow(table, id is mid, commas(
      proposals setTo plist
    )).update.run

  def delete(attachId: Ident): ConnectionIO[Int] =
    deleteFrom(table, id is attachId).update.run
}
