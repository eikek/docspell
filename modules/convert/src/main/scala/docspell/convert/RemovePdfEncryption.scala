/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert

import java.io.ByteArrayOutputStream

import cats.effect._
import fs2.{Chunk, Pipe, Stream}

import docspell.common._
import docspell.logging.Logger

import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.encryption.InvalidPasswordException

/** Using PDFBox, the incoming pdf is loaded while trying the given passwords. */
object RemovePdfEncryption {

  def apply[F[_]: Sync](
      logger: Logger[F],
      passwords: List[Password]
  ): Pipe[F, Byte, Byte] =
    apply(logger, Stream.emits(passwords))

  def apply[F[_]: Sync](
      logger: Logger[F],
      passwords: Stream[F, Password]
  ): Pipe[F, Byte, Byte] = {
    val pws = passwords.cons1(Password.empty)
    in =>
      pws
        .flatMap(pw => in.through(openPdf[F](logger, pw)))
        .head
        .flatMap { doc =>
          if (doc.isEncrypted) {
            logger.stream.debug("Removing protection/encryption from PDF").drain ++
              Stream.eval(Sync[F].delay(doc.setAllSecurityToBeRemoved(true))).drain ++
              toStream[F](doc)
          } else {
            in
          }
        }
        .ifEmpty(
          logger.stream
            .info(
              s"None of the passwords helped to read the given PDF!"
            )
            .drain ++ in
        )
  }

  private def openPdf[F[_]: Sync](
      logger: Logger[F],
      pw: Password
  ): Pipe[F, Byte, PDDocument] = {
    def alloc(bytes: Array[Byte]): F[Option[PDDocument]] =
      Sync[F].delay(load(bytes, pw))

    def free(doc: Option[PDDocument]): F[Unit] =
      Sync[F].delay(doc.foreach(_.close()))

    val log =
      if (pw.isEmpty) Stream.empty
      else
        logger.stream.debug(s"Try opening PDF with password: ${pw.pass.take(2)}***").drain

    in =>
      Stream
        .eval(in.compile.to(Array))
        .flatMap(bytes => log ++ Stream.bracket(alloc(bytes))(free))
        .flatMap(opt => opt.map(Stream.emit).getOrElse(Stream.empty))
  }

  private def load(bytes: Array[Byte], pw: Password): Option[PDDocument] =
    try Option(PDDocument.load(bytes, pw.pass))
    catch {
      case _: InvalidPasswordException =>
        None
    }

  private def toStream[F[_]](doc: PDDocument): Stream[F, Byte] = {
    val baos = new ByteArrayOutputStream()
    doc.save(baos)
    Stream.chunk(Chunk.array(baos.toByteArray))
  }
}
