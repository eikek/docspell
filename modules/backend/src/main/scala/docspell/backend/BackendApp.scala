package docspell.backend

import cats.effect.{Blocker, ConcurrentEffect, ContextShift, Resource}
import docspell.backend.auth.Login
import docspell.backend.ops._
import docspell.backend.signup.OSignup
import docspell.store.Store
import docspell.store.ops.ONode
import docspell.store.queue.JobQueue

import scala.concurrent.ExecutionContext

trait BackendApp[F[_]] {

  def login: Login[F]
  def signup: OSignup[F]
  def collective: OCollective[F]
  def source: OSource[F]
  def tag: OTag[F]
  def equipment: OEquipment[F]
  def organization: OOrganization[F]
  def upload: OUpload[F]
  def node: ONode[F]
  def job: OJob[F]
  def item: OItem[F]
}

object BackendApp {

  def create[F[_]: ConcurrentEffect](
      cfg: Config,
      store: Store[F],
      httpClientEc: ExecutionContext
  ): Resource[F, BackendApp[F]] =
    for {
      queue      <- JobQueue(store)
      loginImpl  <- Login[F](store)
      signupImpl <- OSignup[F](store)
      collImpl   <- OCollective[F](store)
      sourceImpl <- OSource[F](store)
      tagImpl    <- OTag[F](store)
      equipImpl  <- OEquipment[F](store)
      orgImpl    <- OOrganization(store)
      uploadImpl <- OUpload(store, queue, cfg, httpClientEc)
      nodeImpl   <- ONode(store)
      jobImpl    <- OJob(store, httpClientEc)
      itemImpl   <- OItem(store)
    } yield new BackendApp[F] {
      val login: Login[F]            = loginImpl
      val signup: OSignup[F]         = signupImpl
      val collective: OCollective[F] = collImpl
      val source                     = sourceImpl
      val tag                        = tagImpl
      val equipment                  = equipImpl
      val organization               = orgImpl
      val upload                     = uploadImpl
      val node                       = nodeImpl
      val job                        = jobImpl
      val item                       = itemImpl
    }

  def apply[F[_]: ConcurrentEffect: ContextShift](
      cfg: Config,
      connectEC: ExecutionContext,
      httpClientEc: ExecutionContext,
      blocker: Blocker
  ): Resource[F, BackendApp[F]] =
    for {
      store   <- Store.create(cfg.jdbc, connectEC, blocker)
      backend <- create(cfg, store, httpClientEc)
    } yield backend
}
