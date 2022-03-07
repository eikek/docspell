/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import fs2.io.file.Path

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

}
