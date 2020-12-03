package docspell.store.queries

import cats.data.OptionT

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.records.RCollective.{Columns => CC}
import docspell.store.records.RUser.{Columns => UC}
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
    val ucid   = UC.cid.prefix("u")
    val login  = UC.login.prefix("u")
    val pass   = UC.password.prefix("u")
    val ustate = UC.state.prefix("u")
    val cstate = CC.state.prefix("c")
    val ccid   = CC.id.prefix("c")

    val sql = selectSimple(
      List(ucid, login, pass, cstate, ustate),
      RUser.table ++ fr"u, " ++ RCollective.table ++ fr"c",
      and(ucid.is(ccid), login.is(acc.user), ucid.is(acc.collective))
    )

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
