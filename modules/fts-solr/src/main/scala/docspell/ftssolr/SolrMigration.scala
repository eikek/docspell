/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr
import cats.implicits._
import cats.{Applicative, Functor}

import docspell.common._
import docspell.ftsclient.FtsMigration

final case class SolrMigration[F[_]](value: FtsMigration[F], dataChangeOnly: Boolean) {
  def isSchemaChange: Boolean = !dataChangeOnly
}

object SolrMigration {
  private val solrEngine = Ident.unsafe("solr")

  def deleteData[F[_]: Functor](
      version: Int,
      solrUpdate: SolrUpdate[F]
  ): SolrMigration[F] =
    apply(version, "Delete all data", solrUpdate.delete("*:*", Option(0)))

  def writeVersion[F[_]: Functor](
      solrUpdate: SolrUpdate[F],
      doc: VersionDoc
  ): SolrMigration[F] =
    apply(
      Int.MaxValue,
      s"Write current version: ${doc.currentVersion}",
      solrUpdate.updateVersionDoc(doc)
    )

  def reIndexAll[F[_]: Applicative](
      versionNumber: Int,
      description: String
  ): SolrMigration[F] =
    SolrMigration(
      FtsMigration(
        versionNumber,
        solrEngine,
        description,
        FtsMigration.Result.reIndexAll.pure[F]
      ),
      dataChangeOnly = true
    )

  def indexAll[F[_]: Applicative](
      versionNumber: Int,
      description: String
  ): SolrMigration[F] =
    SolrMigration(
      FtsMigration(
        versionNumber,
        solrEngine,
        description,
        FtsMigration.Result.indexAll.pure[F]
      ),
      dataChangeOnly = true
    )

  def apply[F[_]: Functor](
      version: Int,
      description: String,
      task: F[Unit]
  ): SolrMigration[F] =
    SolrMigration(
      FtsMigration(
        version,
        solrEngine,
        description,
        task.map(_ => FtsMigration.Result.workDone)
      ),
      dataChangeOnly = false
    )
}
