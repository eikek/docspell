/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import fs2.io.file.Path

sealed trait FileStoreConfig {
  def enabled: Boolean
  def storeType: FileStoreType
}
object FileStoreConfig {
  case class DefaultDatabase(enabled: Boolean) extends FileStoreConfig {
    val storeType = FileStoreType.DefaultDatabase
  }

  case class FileSystem(
      enabled: Boolean,
      directory: Path
  ) extends FileStoreConfig {
    val storeType = FileStoreType.FileSystem
  }

  case class S3(
      enabled: Boolean,
      endpoint: String,
      accessKey: String,
      secretKey: String,
      bucket: String
  ) extends FileStoreConfig {
    val storeType = FileStoreType.S3

    override def toString =
      s"S3(enabled=$enabled, endpoint=$endpoint, bucket=$bucket, accessKey=$accessKey, secretKey=***)"
  }
}
