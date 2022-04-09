/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import cats.effect._

import docspell.backend.auth.Login
import docspell.backend.fulltext.CreateIndex
import docspell.backend.ops._
import docspell.backend.signup.OSignup
import docspell.ftsclient.FtsClient
import docspell.notification.api.{EventExchange, NotificationModule}
import docspell.pubsub.api.PubSubT
import docspell.scheduler.JobStoreModule
import docspell.store.Store
import docspell.totp.Totp

import emil.Emil

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
  def share: OShare[F]
  def pubSub: PubSubT[F]
  def events: EventExchange[F]
  def notification: ONotification[F]
  def bookmarks: OQueryBookmarks[F]
  def fileRepository: OFileRepository[F]
  def itemLink: OItemLink[F]
  def downloadAll: ODownloadAll[F]
}

object BackendApp {

  def create[F[_]: Async](
      store: Store[F],
      javaEmil: Emil[F],
      ftsClient: FtsClient[F],
      pubSubT: PubSubT[F],
      schedulerModule: JobStoreModule[F],
      notificationMod: NotificationModule[F]
  ): Resource[F, BackendApp[F]] =
    for {
      totpImpl <- OTotp(store, Totp.default)
      loginImpl <- Login[F](store, Totp.default)
      signupImpl <- OSignup[F](store)
      joexImpl <- OJoex(pubSubT)
      collImpl <- OCollective[F](
        store,
        schedulerModule.userTasks,
        schedulerModule.jobs,
        joexImpl
      )
      sourceImpl <- OSource[F](store)
      tagImpl <- OTag[F](store)
      equipImpl <- OEquipment[F](store)
      orgImpl <- OOrganization(store)
      uploadImpl <- OUpload(store, schedulerModule.jobs)
      nodeImpl <- ONode(store)
      jobImpl <- OJob(store, joexImpl, pubSubT)
      createIndex <- CreateIndex.resource(ftsClient, store)
      itemImpl <- OItem(store, ftsClient, createIndex, schedulerModule.jobs)
      itemSearchImpl <- OItemSearch(store)
      fulltextImpl <- OFulltext(
        itemSearchImpl,
        ftsClient,
        store,
        schedulerModule.jobs
      )
      mailImpl <- OMail(store, javaEmil)
      userTaskImpl <- OUserTask(
        schedulerModule.userTasks,
        store,
        joexImpl
      )
      folderImpl <- OFolder(store)
      customFieldsImpl <- OCustomFields(store)
      simpleSearchImpl = OSimpleSearch(fulltextImpl, itemSearchImpl)
      clientSettingsImpl <- OClientSettings(store)
      shareImpl <- Resource.pure(
        OShare(store, itemSearchImpl, simpleSearchImpl, javaEmil)
      )
      notifyImpl <- ONotification(store, notificationMod)
      bookmarksImpl <- OQueryBookmarks(store)
      fileRepoImpl <- OFileRepository(store, schedulerModule.jobs)
      itemLinkImpl <- Resource.pure(OItemLink(store, itemSearchImpl))
      downloadAllImpl <- Resource.pure(ODownloadAll(store, jobImpl, schedulerModule.jobs))
    } yield new BackendApp[F] {
      val pubSub = pubSubT
      val login = loginImpl
      val signup = signupImpl
      val collective = collImpl
      val source = sourceImpl
      val tag = tagImpl
      val equipment = equipImpl
      val organization = orgImpl
      val upload = uploadImpl
      val node = nodeImpl
      val job = jobImpl
      val item = itemImpl
      val itemSearch = itemSearchImpl
      val fulltext = fulltextImpl
      val mail = mailImpl
      val joex = joexImpl
      val userTask = userTaskImpl
      val folder = folderImpl
      val customFields = customFieldsImpl
      val simpleSearch = simpleSearchImpl
      val clientSettings = clientSettingsImpl
      val totp = totpImpl
      val share = shareImpl
      val events = notificationMod
      val notification = notifyImpl
      val bookmarks = bookmarksImpl
      val fileRepository = fileRepoImpl
      val itemLink = itemLinkImpl
      val downloadAll = downloadAllImpl
    }
}
