/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.backend

import scala.concurrent.ExecutionContext

import cats.effect._

import docspell.backend.auth.Login
import docspell.backend.fulltext.CreateIndex
import docspell.backend.ops._
import docspell.backend.signup.OSignup
import docspell.ftsclient.FtsClient
import docspell.joexapi.client.JoexClient
import docspell.store.Store
import docspell.store.queue.JobQueue
import docspell.store.usertask.UserTaskStore

import emil.javamail.{JavaMailEmil, Settings}
import org.http4s.blaze.client.BlazeClientBuilder
import org.http4s.client.Client

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
  def itemSearch: OItemSearch[F]
  def fulltext: OFulltext[F]
  def mail: OMail[F]
  def joex: OJoex[F]
  def userTask: OUserTask[F]
  def folder: OFolder[F]
  def customFields: OCustomFields[F]
  def simpleSearch: OSimpleSearch[F]
  def clientSettings: OClientSettings[F]
  def totp: OTotp[F]
}

object BackendApp {

  def create[F[_]: Async](
      cfg: Config,
      store: Store[F],
      httpClient: Client[F],
      ftsClient: FtsClient[F]
  ): Resource[F, BackendApp[F]] =
    for {
      utStore        <- UserTaskStore(store)
      queue          <- JobQueue(store)
      totpImpl       <- OTotp(store)
      loginImpl      <- Login[F](store)
      signupImpl     <- OSignup[F](store)
      joexImpl       <- OJoex(JoexClient(httpClient), store)
      collImpl       <- OCollective[F](store, utStore, queue, joexImpl)
      sourceImpl     <- OSource[F](store)
      tagImpl        <- OTag[F](store)
      equipImpl      <- OEquipment[F](store)
      orgImpl        <- OOrganization(store)
      uploadImpl     <- OUpload(store, queue, cfg.files, joexImpl)
      nodeImpl       <- ONode(store)
      jobImpl        <- OJob(store, joexImpl)
      createIndex    <- CreateIndex.resource(ftsClient, store)
      itemImpl       <- OItem(store, ftsClient, createIndex, queue, joexImpl)
      itemSearchImpl <- OItemSearch(store)
      fulltextImpl   <- OFulltext(itemSearchImpl, ftsClient, store, queue, joexImpl)
      javaEmil =
        JavaMailEmil(Settings.defaultSettings.copy(debug = cfg.mailDebug))
      mailImpl         <- OMail(store, javaEmil)
      userTaskImpl     <- OUserTask(utStore, queue, joexImpl)
      folderImpl       <- OFolder(store)
      customFieldsImpl <- OCustomFields(store)
      simpleSearchImpl = OSimpleSearch(fulltextImpl, itemSearchImpl)
      clientSettingsImpl <- OClientSettings(store)
    } yield new BackendApp[F] {
      val login          = loginImpl
      val signup         = signupImpl
      val collective     = collImpl
      val source         = sourceImpl
      val tag            = tagImpl
      val equipment      = equipImpl
      val organization   = orgImpl
      val upload         = uploadImpl
      val node           = nodeImpl
      val job            = jobImpl
      val item           = itemImpl
      val itemSearch     = itemSearchImpl
      val fulltext       = fulltextImpl
      val mail           = mailImpl
      val joex           = joexImpl
      val userTask       = userTaskImpl
      val folder         = folderImpl
      val customFields   = customFieldsImpl
      val simpleSearch   = simpleSearchImpl
      val clientSettings = clientSettingsImpl
      val totp           = totpImpl
    }

  def apply[F[_]: Async](
      cfg: Config,
      connectEC: ExecutionContext,
      httpClientEc: ExecutionContext
  )(ftsFactory: Client[F] => Resource[F, FtsClient[F]]): Resource[F, BackendApp[F]] =
    for {
      store      <- Store.create(cfg.jdbc, connectEC)
      httpClient <- BlazeClientBuilder[F](httpClientEc).resource
      ftsClient  <- ftsFactory(httpClient)
      backend    <- create(cfg, store, httpClient, ftsClient)
    } yield backend
}
