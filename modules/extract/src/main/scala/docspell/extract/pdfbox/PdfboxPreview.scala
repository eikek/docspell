/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.pdfbox

import java.awt.image.BufferedImage
import java.awt.image.RenderedImage
import javax.imageio.ImageIO

import cats.effect._
import cats.implicits._
import fs2.Chunk
import fs2.Stream

import org.apache.commons.io.output.ByteArrayOutputStream
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.rendering.PDFRenderer
import scodec.bits.ByteVector

trait PdfboxPreview[F[_]] {

  def previewPNG(pdf: Stream[F, Byte]): F[Option[Stream[F, Byte]]]

}

object PdfboxPreview {

  def apply[F[_]: Sync](cfg: PreviewConfig): F[PdfboxPreview[F]] =
    Sync[F].pure(new PdfboxPreview[F] {

      def previewImage(pdf: Stream[F, Byte]): F[Option[BufferedImage]] =
        PdfLoader.withDocumentStream(pdf)(doc =>
          Sync[F].delay(getPageImage(doc, 0, cfg.dpi))
        )

      def previewPNG(pdf: Stream[F, Byte]): F[Option[Stream[F, Byte]]] =
        previewImage(pdf).map(_.map(pngStream[F]))

    })

  private def getPageImage(
      pdoc: PDDocument,
      page: Int,
      dpi: Float
  ): Option[BufferedImage] = {
    val count = pdoc.getNumberOfPages
    if (count <= 0 || page < 0 || count <= page) None
    else {
      val renderer = new PDFRenderer(pdoc)
      Option(renderer.renderImageWithDPI(page, dpi))
    }
  }

  private def pngStream[F[_]](img: RenderedImage): Stream[F, Byte] = {
    val out = new ByteArrayOutputStream()
    ImageIO.write(img, "PNG", out)
    Stream.chunk(Chunk.byteVector(ByteVector.view(out.toByteArray())))
  }

}
