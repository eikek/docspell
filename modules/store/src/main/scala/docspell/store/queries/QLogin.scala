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
import docspell.store.records.{RCollective, RRememberMe, RUser}

import doobie._
import doobie.implicits._
import org.log4s._

object QLogin {
  private[this] val logger = getLogger

  case class Data(
      account: AccountId,
      password: Password,
      collectiveState: CollectiveState,
      userState: UserState
  )

  def findUser(acc: AccountId): ConnectionIO[Option[Data]] = {
    val user = RUser.as("u")
    val coll = RCollective.as("c")
    val sql =
      Select(
        select(user.cid, user.login, user.password, coll.state, user.state),
        from(user).innerJoin(coll, user.cid === coll.id),
        user.login === acc.user && user.cid === acc.collective
      ).build
    logger.trace(s"SQL : $sql")
    sql.query[Data].option
  }

  def findByRememberMe(
      rememberId: Ident,
      minCreated: Timestamp
  ): OptionT[ConnectionIO, Data] =
    for {
      rem <- OptionT(RRememberMe.useRememberMe(rememberId, minCreated))
      acc <- OptionT(findUser(rem.accountId))
    } yield acc
}
