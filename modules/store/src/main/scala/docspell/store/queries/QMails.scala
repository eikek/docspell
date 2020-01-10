package docspell.store.queries

import cats.data.OptionT
import doobie._
import doobie.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._
import docspell.store.records.{RItem, RSentMail, RSentMailItem, RUser}

object QMails {

  def delete(coll: Ident, mailId: Ident): ConnectionIO[Int] =
    (for {
      m <- OptionT(findMail(coll, mailId))
      k <- OptionT.liftF(RSentMailItem.deleteMail(mailId))
      n <- OptionT.liftF(RSentMail.delete(m._1.id))
    } yield k + n).getOrElse(0)

  def findMail(coll: Ident, mailId: Ident): ConnectionIO[Option[(RSentMail, Ident)]] = {
    val iColl = RItem.Columns.cid.prefix("i")
    val mId   = RSentMail.Columns.id.prefix("m")

    val (cols, from) = partialFind

    val cond = Seq(mId.is(mailId), iColl.is(coll))

    selectSimple(cols, from, and(cond)).query[(RSentMail, Ident)].option
  }

  def findMails(coll: Ident, itemId: Ident): ConnectionIO[Vector[(RSentMail, Ident)]] = {
    val iColl    = RItem.Columns.cid.prefix("i")
    val tItem    = RSentMailItem.Columns.itemId.prefix("t")
    val mCreated = RSentMail.Columns.created.prefix("m")

    val (cols, from) = partialFind

    val cond = Seq(tItem.is(itemId), iColl.is(coll))

    (selectSimple(cols, from, and(cond)) ++ orderBy(mCreated.f) ++ fr"DESC")
      .query[(RSentMail, Ident)]
      .to[Vector]
  }

  private def partialFind: (Seq[Column], Fragment) = {
    val iId    = RItem.Columns.id.prefix("i")
    val tItem  = RSentMailItem.Columns.itemId.prefix("t")
    val tMail  = RSentMailItem.Columns.sentMailId.prefix("t")
    val mId    = RSentMail.Columns.id.prefix("m")
    val mUser  = RSentMail.Columns.uid.prefix("m")
    val uId    = RUser.Columns.uid.prefix("u")
    val uLogin = RUser.Columns.login.prefix("u")

    val cols = RSentMail.Columns.all.map(_.prefix("m")) :+ uLogin
    val from = RSentMail.table ++ fr"m INNER JOIN" ++
      RSentMailItem.table ++ fr"t ON" ++ tMail.is(mId) ++
      fr"INNER JOIN" ++ RItem.table ++ fr"i ON" ++ tItem.is(iId) ++
      fr"INNER JOIN" ++ RUser.table ++ fr"u ON" ++ uId.is(mUser)

    (cols, from)
  }

}
