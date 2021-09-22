/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import docspell.common._

sealed trait SendResult

object SendResult {

  /** Mail was successfully sent and stored to db. */
  case class Success(id: Ident) extends SendResult

  /** There was a failure sending the mail. The mail is then not saved to db. */
  case class SendFailure(ex: Throwable) extends SendResult

  /** The mail was successfully sent, but storing to db failed. */
  case class StoreFailure(ex: Throwable) extends SendResult

  /** Something could not be found required for sending (mail configs, items etc). */
  case object NotFound extends SendResult
}
