/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import fs2.io.file.Path

import docspell.common.FileStoreConfig

sealed trait FileRepositoryConfig {}

object FileRepositoryConfig {

  final case class Database(chunkSize: Int) extends FileRepositoryConfig

  final case class S3(
      endpoint: String,
      accessKey: String,
      secretKey: String,
      bucketName: String,
      chunkSize: Int
  ) extends FileRepositoryConfig

  final case class Directory(path: Path, chunkSize: Int) extends FileRepositoryConfig

  def fromFileStoreConfig(chunkSize: Int, cfg: FileStoreConfig): FileRepositoryConfig =
    cfg match {
      case FileStoreConfig.DefaultDatabase(_) =>
        FileRepositoryConfig.Database(chunkSize)
      case FileStoreConfig.S3(_, endpoint, accessKey, secretKey, bucket) =>
        FileRepositoryConfig.S3(endpoint, accessKey, secretKey, bucket, chunkSize)
      case FileStoreConfig.FileSystem(_, directory) =>
        FileRepositoryConfig.Directory(directory, chunkSize)
    }
}
