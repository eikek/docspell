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
    eventSink: EventSink[F]
) {
  def withPubsub(ps: PubSubT[F]): JobStoreModuleBuilder[F] =
    copy(pubsub = ps)

  def withEventSink(es: EventSink[F]): JobStoreModuleBuilder[F] =
    copy(eventSink = es)

  def build: JobStoreModuleBuilder.Module[F] = {
    val jobStore = JobStorePublish(store, pubsub, eventSink)
    val periodicTaskStore = PeriodicTaskStore(store, jobStore)
    val userTaskStore = UserTaskStoreImpl(store, periodicTaskStore)
    new JobStoreModuleBuilder.Module(
      userTaskStore,
      periodicTaskStore,
      jobStore,
      store,
      eventSink,
      pubsub
    )
  }
}

object JobStoreModuleBuilder {

  def apply[F[_]: Async](store: Store[F]): JobStoreModuleBuilder[F] =
    JobStoreModuleBuilder(store, PubSubT.noop[F], EventSink.silent[F])

  final class Module[F[_]](
      val userTasks: UserTaskStore[F],
      val periodicTaskStore: PeriodicTaskStore[F],
      val jobs: JobStore[F],
      val store: Store[F],
      val eventSink: EventSink[F],
      val pubSubT: PubSubT[F]
  ) extends JobStoreModule[F] {}
}
