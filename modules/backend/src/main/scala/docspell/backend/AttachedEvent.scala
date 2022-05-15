/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import docspell.common._
import docspell.notification.api.Event

trait AttachedEvent[R] {

  def value: R

  def event(account: AccountId, baseUrl: Option[LenientUri]): Iterable[Event]

  def map[U](f: R => U): AttachedEvent[U]
}

object AttachedEvent {

  /** Only the result, no events. */
  def only[R](v: R): AttachedEvent[R] =
    new AttachedEvent[R] {
      val value = v
      def event(account: AccountId, baseUrl: Option[LenientUri]): Iterable[Event] =
        Iterable.empty[Event]

      def map[U](f: R => U): AttachedEvent[U] =
        only(f(v))
    }

  def apply[R](
      v: R
  )(mkEvent: (AccountId, Option[LenientUri]) => Event): AttachedEvent[R] =
    new AttachedEvent[R] {
      val value = v
      def event(account: AccountId, baseUrl: Option[LenientUri]): Iterable[Event] =
        Some(mkEvent(account, baseUrl))

      def map[U](f: R => U): AttachedEvent[U] =
        apply(f(v))(mkEvent)
    }
}
