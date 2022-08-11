/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import docspell.common.AccountId
import docspell.scheduler.FindJobOwner
import docspell.store.Store
import docspell.store.queries.QLogin

/** Finds the job submitter account by using the group as collective and submitter as
  * login.
  */
object FindJobOwnerAccount {
  def apply[F[_]](store: Store[F]): FindJobOwner[F] =
    FindJobOwner.of { job =>
      val accountId = AccountId(job.group, job.submitter)
      store.transact(QLogin.findAccount(accountId))
    }
}
