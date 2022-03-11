/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.BackendApp
import docspell.common.FileCopyTaskArgs.Selection
import docspell.common.{FileCopyTaskArgs, FileIntegrityCheckArgs, FileKeyPart}
import docspell.restapi.model._

import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object FileRepositoryRoutes {

  def admin[F[_]: Async](backend: BackendApp[F]): HttpRoutes[F] = {
    val dsl = Http4sDsl[F]
    import dsl._
    val logger = docspell.logging.getLogger[F]

    HttpRoutes.of {
      case req @ POST -> Root / "cloneFileRepository" =>
        for {
          input <- req.as[FileRepositoryCloneRequest]
          args = makeTaskArgs(input)
          job <- backend.fileRepository.cloneFileRepository(args, true)
          result = BasicResult(
            job.isDefined,
            job.fold(s"Job for '${FileCopyTaskArgs.taskName.id}' already running")(j =>
              s"Job for '${FileCopyTaskArgs.taskName.id}' submitted: ${j.id.id}"
            )
          )
          _ <- logger.info(result.message)
          resp <- Ok(result)
        } yield resp

      case req @ POST -> Root / "integrityCheck" =>
        for {
          input <- req.as[FileKeyPart]
          job <- backend.fileRepository.checkIntegrityAll(input, true)
          result = BasicResult(
            job.isDefined,
            job.fold(s"Job for '${FileCopyTaskArgs.taskName.id}' already running")(j =>
              s"Job for '${FileIntegrityCheckArgs.taskName.id}' submitted: ${j.id.id}"
            )
          )
          _ <- logger.info(result.message)
          resp <- Ok(result)
        } yield resp
    }
  }

  def makeTaskArgs(input: FileRepositoryCloneRequest): FileCopyTaskArgs =
    NonEmptyList.fromList(input.targetRepositories) match {
      case Some(nel) =>
        FileCopyTaskArgs(None, Selection.Stores(nel))
      case None =>
        FileCopyTaskArgs(None, Selection.All)
    }
}
