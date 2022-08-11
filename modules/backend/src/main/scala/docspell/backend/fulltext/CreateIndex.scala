/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.fulltext

import cats.data.NonEmptyList
import cats.effect._

import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.ftsclient.TextData
import docspell.logging.Logger
import docspell.store.Store
import docspell.store.queries.QAttachment
import docspell.store.queries.QItem

trait CreateIndex[F[_]] {

  /** Low-level function to re-index data. It is not submitted as a job, but invoked on
    * the current machine.
    */
  def reIndexData(
      logger: Logger[F],
      collective: Option[CollectiveId],
      itemIds: Option[NonEmptyList[Ident]],
      chunkSize: Int
  ): F[Unit]

}

object CreateIndex {

  def resource[F[_]](fts: FtsClient[F], store: Store[F]): Resource[F, CreateIndex[F]] =
    Resource.pure(apply(fts, store))

  def apply[F[_]](fts: FtsClient[F], store: Store[F]): CreateIndex[F] =
    new CreateIndex[F] {
      def reIndexData(
          logger: Logger[F],
          collective: Option[CollectiveId],
          itemIds: Option[NonEmptyList[Ident]],
          chunkSize: Int
      ): F[Unit] = {
        val attachs = store
          .transact(
            QAttachment.allAttachmentMetaAndName(
              collective,
              itemIds,
              ItemState.validStates,
              chunkSize
            )
          )
          .map(caa =>
            TextData
              .attachment(
                caa.item,
                caa.id,
                caa.collective,
                caa.folder,
                caa.lang,
                caa.name,
                caa.content
              )
          )

        val items = store
          .transact(QItem.allNameAndNotes(collective, itemIds, chunkSize))
          .map(nn =>
            TextData.item(
              nn.id,
              nn.collective,
              nn.folder,
              Option(nn.name),
              nn.notes,
              nn.language
            )
          )

        fts.indexData(logger, attachs ++ items)
      }
    }

}
