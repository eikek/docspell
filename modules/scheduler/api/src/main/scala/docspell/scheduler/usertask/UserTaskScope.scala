/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.usertask

import docspell.common._
import docspell.scheduler.usertask.UserTaskScope._

sealed trait UserTaskScope { self: Product =>

  def name: String =
    productPrefix.toLowerCase

  def collectiveId: Option[CollectiveId]

  def fold[A](fa: Account => A, fb: CollectiveId => A, fc: => A): A

  /** Maps to the account or uses the collective for both parts if the scope is collective
    * wide.
    */
  protected[scheduler] def toAccountId: AccountId
}

object UserTaskScope {

  final case class Account(collective: CollectiveId, userId: Ident)
      extends UserTaskScope {
    val collectiveId = Some(collective)

    def fold[A](fa: Account => A, fb: CollectiveId => A, fc: => A): A =
      fa(this)

    protected[scheduler] val toAccountId: AccountId =
      AccountId(collective.valueAsIdent, userId)
  }

  final case class Collective(collective: CollectiveId) extends UserTaskScope {
    val collectiveId = Some(collective)
    def fold[A](fa: Account => A, fb: CollectiveId => A, fc: => A): A =
      fb(collective)

    protected[scheduler] val toAccountId: AccountId = {
      val c = collective.valueAsIdent
      AccountId(c, c)
    }
  }

  case object System extends UserTaskScope {
    val collectiveId = None

    def fold[A](fa: Account => A, fb: CollectiveId => A, fc: => A): A =
      fc

    protected[scheduler] val toAccountId: AccountId =
      DocspellSystem.account
  }

  def collective(id: CollectiveId): UserTaskScope =
    Collective(id)

  def account(collectiveId: CollectiveId, userId: Ident): UserTaskScope =
    Account(collectiveId, userId)

  def apply(collectiveId: CollectiveId, userId: Option[Ident]): UserTaskScope =
    userId.map(Account(collectiveId, _)).getOrElse(collective(collectiveId))

  def apply(info: AccountInfo): UserTaskScope =
    account(info.collectiveId, info.userId)

  def system: UserTaskScope =
    UserTaskScope.System
}
