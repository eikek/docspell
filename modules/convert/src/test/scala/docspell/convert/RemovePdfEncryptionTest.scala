/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import cats.effect.IO
import fs2.Stream

import docspell.common._
import docspell.files.ExampleFiles
import docspell.logging.{Logger, TestLoggingConfig}

import munit.CatsEffectSuite

class RemovePdfEncryptionTest
    extends CatsEffectSuite
    with FileChecks
    with TestLoggingConfig {
  val logger: Logger[IO] = docspell.logging.getLogger[IO]

  private val protectedPdf =
    ExampleFiles.secured_protected_test123_pdf.readURL[IO](16 * 1024)
  private val encryptedPdf =
    ExampleFiles.secured_encrypted_test123_pdf.readURL[IO](16 * 1024)
  private val plainPdf = ExampleFiles.letter_en_pdf.readURL[IO](16 * 1024)

  test("have encrypted pdfs") {
    for {
      _ <- assertIO(encryptedPdf.isEncryptedPDF, true)
      _ <- assertIO(encryptedPdf.isEncryptedPDF, true)
    } yield ()
  }

  test("decrypt pdf") {
    encryptedPdf
      .through(RemovePdfEncryption(logger, List(Password("test123"))))
      .isUnencryptedPDF
      .map(assert(_))
  }

  test("decrypt pdf with multiple passwords") {
    encryptedPdf
      .through(
        RemovePdfEncryption(
          logger,
          List("xy123", "123xy", "test123", "abc123").map(Password(_))
        )
      )
      .isUnencryptedPDF
      .map(assert(_))
  }

  test("remove protection") {
    protectedPdf
      .through(RemovePdfEncryption(logger, Nil))
      .isUnencryptedPDF
      .map(assert(_))
  }

  test("read unprotected pdf") {
    plainPdf
      .through(RemovePdfEncryption(logger, Nil))
      .isUnencryptedPDF
      .map(assert(_))
  }

  test("decrypt with multiple passwords, stop on first") {
    val passwords: Stream[IO, String] =
      Stream("test123") ++ Stream.raiseError[IO](new Exception("is not called"))
    val decrypt = RemovePdfEncryption(logger, passwords.map(Password(_)))
    encryptedPdf
      .through(decrypt)
      .isUnencryptedPDF
      .map(assert(_))
  }

  test("return input stream if nothing helps") {
    encryptedPdf
      .through(RemovePdfEncryption(logger, List("a", "b").map(Password(_))))
      .isEncryptedPDF
      .map(assert(_))
  }
}
