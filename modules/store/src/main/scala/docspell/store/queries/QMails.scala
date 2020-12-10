package docspell.store.queries

import cats.data.OptionT

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QMails {

  def delete(coll: Ident, mailId: Ident): ConnectionIO[Int] =
    (for {
      m <- OptionT(findMail(coll, mailId))
      k <- OptionT.liftF(RSentMailItem.deleteMail(mailId))
      n <- OptionT.liftF(RSentMail.delete(m._1.id))
    } yield k + n).getOrElse(0)

  def findMail(coll: Ident, mailId: Ident): ConnectionIO[Option[(RSentMail, Ident)]] = {
    val iColl = RItem.Columns.cid.prefix("i")
    val smail = RSentMail.as("m")
    val mId   = smail.id.column

    val (cols, from) = partialFind

    val cond = Seq(mId.is(mailId), iColl.is(coll))

    selectSimple(cols, from, and(cond)).query[(RSentMail, Ident)].option
  }

  def findMails(coll: Ident, itemId: Ident): ConnectionIO[Vector[(RSentMail, Ident)]] = {
    val smailitem = RSentMailItem.as("t")
    val smail     = RSentMail.as("m")
    val iColl     = RItem.Columns.cid.prefix("i")
    val tItem     = smailitem.itemId.column
    val mCreated  = smail.created.column

    val (cols, from) = partialFind

    val cond = Seq(tItem.is(itemId), iColl.is(coll))

    (selectSimple(cols, from, and(cond)) ++ orderBy(mCreated.f) ++ fr"DESC")
      .query[(RSentMail, Ident)]
      .to[Vector]
  }

  private def partialFind: (Seq[Column], Fragment) = {
    val user      = RUser.as("u")
    val smailitem = RSentMailItem.as("t")
    val smail     = RSentMail.as("m")
    val iId       = RItem.Columns.id.prefix("i")
    val tItem     = smailitem.itemId.column
    val tMail     = smailitem.sentMailId.column
    val mId       = smail.id.column
    val mUser     = smail.uid.column

    val cols = smail.all.map(_.column) :+ user.login.column
    val from = Fragment.const(smail.tableName) ++ fr"m INNER JOIN" ++
      Fragment.const(smailitem.tableName) ++ fr"t ON" ++ tMail.is(mId) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ tItem.is(iId) ++
      fr"INNER JOIN" ++ Fragment.const(user.tableName) ++ fr"u ON" ++ user.uid.column.is(
        mUser
      )

    (cols, from)
  }

}
