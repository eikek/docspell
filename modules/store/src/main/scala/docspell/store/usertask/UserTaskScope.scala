/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.usertask

import docspell.common._

sealed trait UserTaskScope { self: Product =>

  def name: String =
    productPrefix.toLowerCase

  def collective: Ident

  def fold[A](fa: AccountId => A, fb: Ident => A): A

  /** Maps to the account or uses the collective for both parts if the
    * scope is collective wide.
    */
  private[usertask] def toAccountId: AccountId =
    AccountId(collective, fold(_.user, identity))
}

object UserTaskScope {

  final case class Account(account: AccountId) extends UserTaskScope {
    val collective = account.collective

    def fold[A](fa: AccountId => A, fb: Ident => A): A =
      fa(account)
  }

  final case class Collective(collective: Ident) extends UserTaskScope {
    def fold[A](fa: AccountId => A, fb: Ident => A): A =
      fb(collective)
  }

  def collective(id: Ident): UserTaskScope =
    Collective(id)

  def account(accountId: AccountId): UserTaskScope =
    Account(accountId)

  def apply(accountId: AccountId): UserTaskScope =
    UserTaskScope.account(accountId)

  def apply(collective: Ident): UserTaskScope =
    UserTaskScope.collective(collective)
}
