/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import cats.data.OptionT

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QMails {

  private val item     = RItem.as("i")
  private val smail    = RSentMail.as("sm")
  private val mailitem = RSentMailItem.as("mi")
  private val user     = RUser.as("u")

  def delete(coll: Ident, mailId: Ident): ConnectionIO[Int] =
    (for {
      m <- OptionT(findMail(coll, mailId))
      k <- OptionT.liftF(RSentMailItem.deleteMail(mailId))
      n <- OptionT.liftF(RSentMail.delete(m._1.id))
    } yield k + n).getOrElse(0)

  def findMail(coll: Ident, mailId: Ident): ConnectionIO[Option[(RSentMail, Ident)]] =
    partialFind
      .where(smail.id === mailId && item.cid === coll)
      .build
      .query[(RSentMail, Ident)]
      .option

  def findMails(coll: Ident, itemId: Ident): ConnectionIO[Vector[(RSentMail, Ident)]] =
    partialFind
      .where(mailitem.itemId === itemId && item.cid === coll)
      .orderBy(smail.created.desc)
      .build
      .query[(RSentMail, Ident)]
      .to[Vector]

  private def partialFind: Select.SimpleSelect =
    Select(
      select(smail.all).append(user.login.s),
      from(smail)
        .innerJoin(mailitem, mailitem.sentMailId === smail.id)
        .innerJoin(item, mailitem.itemId === item.id)
        .innerJoin(user, user.uid === smail.uid)
    )

}
