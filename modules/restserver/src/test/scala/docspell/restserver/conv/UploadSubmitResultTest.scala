/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.conv

import docspell.backend.ops.OUpload
import docspell.common._
import docspell.restapi.model.UploadSubmitResult

import munit.FunSuite

class UploadSubmitResultTest extends FunSuite with Conversions {

  test("map Success to UploadSubmitResult with fileKeys and jobIds") {
    val fileKey =
      FileKey(CollectiveId(1), FileCategory.AttachmentSource, Ident.unsafe("file-1"))
    val jobId = Ident.unsafe("job-1")
    val result =
      uploadSubmitResult(OUpload.UploadResult.Success(List(fileKey), List(jobId)))

    assertEquals(
      result,
      UploadSubmitResult(
        success = true,
        "Files submitted.",
        List(fileKey.toString),
        List(jobId)
      )
    )
  }

  test("map failures to empty fileKeys and jobIds") {
    val cases = List(
      OUpload.UploadResult.NoFiles,
      OUpload.UploadResult.NoSource,
      OUpload.UploadResult.NoItem,
      OUpload.UploadResult.NoCollective,
      OUpload.UploadResult.StoreFailure(new RuntimeException("boom"))
    )

    cases.foreach { ur =>
      val result = uploadSubmitResult(ur)
      assertEquals(result.success, false)
      assertEquals(result.fileKeys, Nil)
      assertEquals(result.jobIds, Nil)
    }
  }
}
