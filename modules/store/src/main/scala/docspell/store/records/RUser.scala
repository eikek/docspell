package docspell.store.records

import doobie._, doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

case class RUser(
    uid: Ident,
    login: Ident,
    cid: Ident,
    password: Password,
    state: UserState,
    email: Option[String],
    loginCount: Int,
    lastLogin: Option[Timestamp],
    created: Timestamp
) {}

object RUser {

  val table = fr"user_"

  object Columns {
    val uid        = Column("uid")
    val cid        = Column("cid")
    val login      = Column("login")
    val password   = Column("password")
    val state      = Column("state")
    val email      = Column("email")
    val loginCount = Column("logincount")
    val lastLogin  = Column("lastlogin")
    val created    = Column("created")

    val all =
      List(uid, login, cid, password, state, email, loginCount, lastLogin, created)
  }

  import Columns._

  def insert(v: RUser): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      Columns.all,
      fr"${v.uid},${v.login},${v.cid},${v.password},${v.state},${v.email},${v.loginCount},${v.lastLogin},${v.created}"
    )
    sql.update.run
  }

  def update(v: RUser): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      and(login.is(v.login), cid.is(v.cid)),
      commas(
        state.setTo(v.state),
        email.setTo(v.email),
        loginCount.setTo(v.loginCount),
        lastLogin.setTo(v.lastLogin)
      )
    )
    sql.update.run
  }

  def exists(loginName: Ident): ConnectionIO[Boolean] =
    selectCount(uid, table, login.is(loginName)).query[Int].unique.map(_ > 0)

  def findByAccount(aid: AccountId): ConnectionIO[Option[RUser]] = {
    val sql = selectSimple(all, table, and(cid.is(aid.collective), login.is(aid.user)))
    sql.query[RUser].option
  }

  def findById(userId: Ident): ConnectionIO[Option[RUser]] = {
    val sql = selectSimple(all, table, uid.is(userId))
    sql.query[RUser].option
  }

  def findAll(coll: Ident, order: Columns.type => Column): ConnectionIO[Vector[RUser]] = {
    val sql = selectSimple(all, table, cid.is(coll)) ++ orderBy(order(Columns).f)
    sql.query[RUser].to[Vector]
  }

  def updateLogin(accountId: AccountId): ConnectionIO[Int] =
    currentTime.flatMap(t =>
      updateRow(
        table,
        and(cid.is(accountId.collective), login.is(accountId.user)),
        commas(
          loginCount.f ++ fr"=" ++ loginCount.f ++ fr"+ 1",
          lastLogin.setTo(t)
        )
      ).update.run
    )

  def updatePassword(accountId: AccountId, hashedPass: Password): ConnectionIO[Int] =
    updateRow(
      table,
      and(cid.is(accountId.collective), login.is(accountId.user)),
      password.setTo(hashedPass)
    ).update.run

  def delete(user: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(cid.is(coll), login.is(user))).update.run
}
