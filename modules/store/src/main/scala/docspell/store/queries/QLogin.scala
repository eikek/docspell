/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.data.OptionT
import cats.syntax.all._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records.{RCollective, RRememberMe, RUser}

import doobie._
import doobie.implicits._

object QLogin {
  private[this] val logger = docspell.logging.getLogger[ConnectionIO]

  case class Data(
      account: AccountInfo,
      password: Password,
      collectiveState: CollectiveState,
      userState: UserState,
      source: AccountSource
  )

  private def findUser0(
      where: (RUser.Table, RCollective.Table) => Condition
  ): ConnectionIO[Option[Data]] = {
    val user = RUser.as("u")
    val coll = RCollective.as("c")
    val sql =
      Select(
        select(
          coll.id,
          coll.name,
          user.uid,
          user.login,
          user.password,
          coll.state,
          user.state,
          user.source
        ),
        from(user).innerJoin(coll, user.cid === coll.id),
        where(user, coll)
      ).build
    logger.trace(s"SQL : $sql") *>
      sql.query[Data].option
  }

  def findUser(acc: AccountId): ConnectionIO[Option[Data]] =
    findUser0((user, coll) => user.login === acc.user && coll.name === acc.collective)

  def findUser(userId: Ident): ConnectionIO[Option[Data]] =
    findUser0((user, _) => user.uid === userId)

  /** Finds the account given a combination of login/user-id and coll-id/coll-name pair.
    */
  def findAccount(acc: AccountId): ConnectionIO[Option[AccountInfo]] = {
    val collIdOpt = acc.collective.id.toLongOption.map(CollectiveId(_))
    findUser0((ut, ct) =>
      (ut.login === acc.user || ut.uid === acc.user) && collIdOpt
        .map(id => ct.id === id)
        .getOrElse(ct.name === acc.collective)
    )
      .map(_.map(_.account))
  }

  def findByRememberMe(
      rememberId: Ident,
      minCreated: Timestamp
  ): OptionT[ConnectionIO, Data] =
    for {
      rem <- OptionT(RRememberMe.useRememberMe(rememberId, minCreated))
      acc <- OptionT(findUser(rem.userId))
    } yield acc
}
