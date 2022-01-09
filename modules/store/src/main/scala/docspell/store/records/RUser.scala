/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import cats.data.OptionT
import cats.effect.Sync

case class RUser(
    uid: Ident,
    login: Ident,
    cid: Ident,
    password: Password,
    state: UserState,
    source: AccountSource,
    email: Option[String],
    loginCount: Int,
    lastLogin: Option[Timestamp],
    created: Timestamp
) {
  def accountId: AccountId =
    AccountId(cid, login)

  def idRef: IdRef =
    IdRef(uid, login.id)
}

object RUser {

  def makeDefault(
      id: Ident,
      login: Ident,
      collName: Ident,
      password: Password,
      source: AccountSource,
      created: Timestamp
  ): RUser =
    RUser(
      id,
      login,
      collName,
      password,
      UserState.Active,
      source,
      None,
      0,
      None,
      created
    )

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "user_"

    val uid = Column[Ident]("uid", this)
    val login = Column[Ident]("login", this)
    val cid = Column[Ident]("cid", this)
    val password = Column[Password]("password", this)
    val state = Column[UserState]("state", this)
    val source = Column[AccountSource]("account_source", this)
    val email = Column[String]("email", this)
    val loginCount = Column[Int]("logincount", this)
    val lastLogin = Column[Timestamp]("lastlogin", this)
    val created = Column[Timestamp]("created", this)

    def isAccount(aid: AccountId) =
      cid === aid.collective && login === aid.user

    val all =
      NonEmptyList.of[Column[_]](
        uid,
        login,
        cid,
        password,
        state,
        source,
        email,
        loginCount,
        lastLogin,
        created
      )
  }

  val T = Table(None)

  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RUser): ConnectionIO[Int] = {
    val t = Table(None)
    DML.insert(
      t,
      t.all,
      fr"${v.uid},${v.login},${v.cid},${v.password},${v.state},${v.source},${v.email},${v.loginCount},${v.lastLogin},${v.created}"
    )
  }

  def update(v: RUser): ConnectionIO[Int] = {
    val t = Table(None)
    DML.update(
      t,
      t.login === v.login && t.cid === v.cid,
      DML.set(
        t.state.setTo(v.state),
        t.email.setTo(v.email),
        t.loginCount.setTo(v.loginCount),
        t.lastLogin.setTo(v.lastLogin)
      )
    )
  }

  def exists(loginName: Ident): ConnectionIO[Boolean] = {
    val t = Table(None)
    run(select(count(t.uid)), from(t), t.login === loginName).query[Int].unique.map(_ > 0)
  }

  def findByAccount(aid: AccountId): ConnectionIO[Option[RUser]] = {
    val t = Table(None)
    val sql =
      run(select(t.all), from(t), t.cid === aid.collective && t.login === aid.user)
    sql.query[RUser].option
  }

  def findById(userId: Ident): ConnectionIO[Option[RUser]] = {
    val t = Table(None)
    val sql = run(select(t.all), from(t), t.uid === userId)
    sql.query[RUser].option
  }

  def findAll(coll: Ident, order: Table => Column[_]): ConnectionIO[Vector[RUser]] = {
    val t = Table(None)
    val sql = Select(select(t.all), from(t), t.cid === coll).orderBy(order(t)).build
    sql.query[RUser].to[Vector]
  }

  def findIdByAccount(accountId: AccountId): ConnectionIO[Option[Ident]] =
    run(
      select(T.uid),
      from(T),
      T.login === accountId.user && T.cid === accountId.collective
    )
      .query[Ident]
      .option

  def getIdByAccount(account: AccountId): ConnectionIO[Ident] =
    OptionT(findIdByAccount(account)).getOrElseF(
      Sync[ConnectionIO].raiseError(
        new Exception(s"No user found for: ${account.asString}")
      )
    )

  def updateLogin(accountId: AccountId): ConnectionIO[Int] = {
    val t = Table(None)
    def stmt(now: Timestamp) =
      DML.update(
        t,
        t.cid === accountId.collective && t.login === accountId.user,
        DML.set(
          t.loginCount.increment(1),
          t.lastLogin.setTo(now)
        )
      )
    Timestamp.current[ConnectionIO].flatMap(stmt)
  }

  def updatePassword(accountId: AccountId, hashedPass: Password): ConnectionIO[Int] = {
    val t = Table(None)
    DML.update(
      t,
      t.cid === accountId.collective && t.login === accountId.user && t.source === AccountSource.Local,
      DML.set(t.password.setTo(hashedPass))
    )
  }

  def delete(user: Ident, coll: Ident): ConnectionIO[Int] = {
    val t = Table(None)
    DML.delete(t, t.cid === coll && t.login === user)
  }

  def deleteById(uid: Ident): ConnectionIO[Int] =
    DML.delete(T, T.uid === uid)
}
