/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.impl

import cats.effect.Async

import docspell.notification.api.EventSink
import docspell.pubsub.api.PubSubT
import docspell.scheduler._
import docspell.scheduler.usertask.UserTaskStore
import docspell.store.Store

case class JobStoreModuleBuilder[F[_]: Async](
    store: Store[F],
    pubsub: PubSubT[F],
    eventSink: EventSink[F],
    findJobOwner: FindJobOwner[F]
) {
  def withPubsub(ps: PubSubT[F]): JobStoreModuleBuilder[F] =
    copy(pubsub = ps)

  def withEventSink(es: EventSink[F]): JobStoreModuleBuilder[F] =
    copy(eventSink = es)

  def withFindJobOwner(f: FindJobOwner[F]): JobStoreModuleBuilder[F] =
    copy(findJobOwner = f)

  def build: JobStoreModuleBuilder.Module[F] = {
    val jobStore = JobStorePublish(store, pubsub, eventSink, findJobOwner)
    val periodicTaskStore = PeriodicTaskStore(store, jobStore)
    val userTaskStore = UserTaskStoreImpl(store, periodicTaskStore)
    new JobStoreModuleBuilder.Module(
      userTaskStore,
      periodicTaskStore,
      jobStore,
      store,
      eventSink,
      pubsub,
      findJobOwner
    )
  }
}

object JobStoreModuleBuilder {

  def apply[F[_]: Async](store: Store[F]): JobStoreModuleBuilder[F] =
    JobStoreModuleBuilder(
      store,
      PubSubT.noop[F],
      EventSink.silent[F],
      FindJobOwner.none[F]
    )

  final class Module[F[_]](
      val userTasks: UserTaskStore[F],
      val periodicTaskStore: PeriodicTaskStore[F],
      val jobs: JobStore[F],
      val store: Store[F],
      val eventSink: EventSink[F],
      val pubSubT: PubSubT[F],
      val findJobOwner: FindJobOwner[F]
  ) extends JobStoreModule[F] {}
}
