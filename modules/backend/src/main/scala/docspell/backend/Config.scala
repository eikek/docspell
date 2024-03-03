/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import cats.data.{Validated, ValidatedNec}
import cats.implicits._

import docspell.backend.signup.{Config => SignupConfig}
import docspell.common._
import docspell.common.syntax.string._
import docspell.store.file.FileRepositoryConfig
import docspell.store.{JdbcConfig, SchemaMigrateConfig}

import emil.javamail.Settings

case class Config(
    mailDebug: Boolean,
    jdbc: JdbcConfig,
    databaseSchema: SchemaMigrateConfig,
    signup: SignupConfig,
    files: Config.Files,
    addons: Config.Addons
) {

  def mailSettings: Settings =
    Settings.defaultSettings.copy(debug = mailDebug)

}

object Config {

  case class Files(
      chunkSize: Int,
      validMimeTypes: Seq[MimeType],
      defaultStore: Ident,
      stores: Map[Ident, FileStoreConfig]
  ) {
    val enabledStores: Map[Ident, FileStoreConfig] =
      stores.view.filter(_._2.enabled).toMap

    def defaultStoreConfig: FileStoreConfig =
      enabledStores(defaultStore)

    def defaultFileRepositoryConfig: FileRepositoryConfig =
      FileRepositoryConfig.fromFileStoreConfig(chunkSize, defaultStoreConfig)

    def getFileRepositoryConfig(id: Ident): Option[FileRepositoryConfig] =
      stores.get(id).map(FileRepositoryConfig.fromFileStoreConfig(chunkSize, _))

    def validate: ValidatedNec[String, Files] = {
      def filterEmptyRegion =
        copy(stores = stores.view.mapValues {
          case c: FileStoreConfig.S3 => c.copy(region = c.region.flatMap(_.asNonBlank))
          case c                     => c
        }.toMap)

      val storesEmpty =
        if (enabledStores.isEmpty)
          Validated.invalidNec(
            "No file stores defined! Make sure at least one enabled store is present."
          )
        else Validated.validNec(())

      val defaultStorePresent =
        enabledStores.get(defaultStore) match {
          case Some(_) => Validated.validNec(())
          case None =>
            Validated.invalidNec(s"Default file store not present: ${defaultStore.id}")
        }

      (storesEmpty |+| defaultStorePresent).map(_ => filterEmptyRegion)
    }
  }

  case class Addons(
      enabled: Boolean,
      allowImpure: Boolean,
      allowedUrls: UrlMatcher,
      deniedUrls: UrlMatcher
  ) {
    def isAllowed(url: LenientUri): Boolean =
      allowedUrls.matches(url) && !deniedUrls.matches(url)

    def isDenied(url: LenientUri): Boolean =
      !isAllowed(url)
  }
  object Addons {
    val disabled: Addons =
      Addons(enabled = false, allowImpure = false, UrlMatcher.False, UrlMatcher.True)
  }
}
