/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import fs2.Stream

import docspell.common._
import docspell.scheduler.impl.JobStoreImpl
import docspell.store.records.RCollective
import docspell.store.{DatabaseTest, Store}

class OUploadTest extends DatabaseTest {

  override def munitFixtures = h2Memory

  test("submit returns file keys and job ids for uploaded file") {
    val store = h2Store()
    val content = "hello-upload".getBytes("UTF-8")

    OUpload[IO](store, JobStoreImpl(store)).use { upload =>
      for {
        cid <- prepareCollective(store)
        data = OUpload.UploadData(
          multiple = true,
          meta = OUpload.UploadMeta(
            direction = None,
            sourceAbbrev = "webapp",
            folderId = None,
            validFileTypes = Seq.empty,
            skipDuplicates = false,
            fileFilter = Glob.all,
            tags = Nil,
            language = Some(Language.English),
            attachmentsOnly = None,
            flattenArchives = None,
            customData = None,
            priority = None
          ),
          files = Vector(
            OUpload.File(
              Some("test.txt"),
              Some(MimeType.plain),
              Stream.emits(content).covary[IO]
            )
          ),
          priority = Priority.High,
          tracker = None
        )
        result <- upload.submit(data, cid, None, None)
      } yield result match {
        case OUpload.UploadResult.Success(files, jobs) =>
          assertEquals(files.size, 1)
          assertEquals(jobs.size, 1)
          assertEquals(files.head.collective, cid)
          assertEquals(files.head.category, FileCategory.AttachmentSource)
        case other =>
          fail(s"expected Success, got $other")
      }
    }
  }

  test("submitted file can be loaded by returned file key") {
    val store = h2Store()
    val content = "retrieve-me".getBytes("UTF-8")

    OUpload[IO](store, JobStoreImpl(store)).use { upload =>
      OItemSearch[IO](store).use { search =>
        for {
          cid <- prepareCollective(store)
          data = OUpload.UploadData(
            multiple = true,
            meta = OUpload.UploadMeta(
              direction = None,
              sourceAbbrev = "webapp",
              folderId = None,
              validFileTypes = Seq.empty,
              skipDuplicates = false,
              fileFilter = Glob.all,
              tags = Nil,
              language = Some(Language.English),
              attachmentsOnly = None,
              flattenArchives = None,
              customData = None,
              priority = None
            ),
            files = Vector(
              OUpload.File(
                Some("doc.pdf"),
                None,
                Stream.emits(content).covary[IO]
              )
            ),
            priority = Priority.Low,
            tracker = None
          )
          result <- upload.submit(data, cid, None, None)
          file <- result match {
            case OUpload.UploadResult.Success(files, _) =>
              files.headOption match {
                case Some(f) => IO.pure(f)
                case None =>
                  IO.raiseError(new Exception("expected at least one file key"))
              }
            case other =>
              IO.raiseError(new Exception(s"expected Success, got $other"))
          }
          loaded <- search.findFile(file, cid)
          bytes <- loaded match {
            case Some(bin) => bin.data.compile.to(Array)
            case None      => IO.raiseError(new Exception("file not found via findFile"))
          }
        } yield assertEquals(bytes.toSeq, content.toSeq)
      }
    }
  }

  private def prepareCollective(store: Store[IO]): IO[CollectiveId] =
    Ident
      .randomId[IO]
      .flatMap { name =>
        store.transact(
          RCollective.insert(
            RCollective(
              CollectiveId.unknown,
              name,
              CollectiveState.Active,
              Language.English,
              integrationEnabled = true,
              Timestamp.Epoch
            )
          )
        )
      }
}
