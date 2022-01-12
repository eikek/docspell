/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.pdfbox

import java.awt.RenderingHints
import java.awt.image.BufferedImage
import java.awt.image.RenderedImage
import javax.imageio.ImageIO

import scala.jdk.CollectionConverters._

import cats.effect._
import cats.implicits._
import fs2.Chunk
import fs2.Stream

import org.apache.commons.io.output.ByteArrayOutputStream
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.PDPage
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject
import org.apache.pdfbox.rendering.PDFRenderer
import scodec.bits.ByteVector

trait PdfboxPreview[F[_]] {

  def previewPNG(pdf: Stream[F, Byte]): F[Option[Stream[F, Byte]]]

}

object PdfboxPreview {
  private[this] val logger = org.log4s.getLogger

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
      renderer.setImageDownscalingOptimizationThreshold(0.85f)
      val hints = new RenderingHints(
        RenderingHints.KEY_RENDERING,
        RenderingHints.VALUE_RENDER_QUALITY
      )
      hints.put(
        RenderingHints.KEY_COLOR_RENDERING,
        RenderingHints.VALUE_COLOR_RENDER_QUALITY
      )
      hints.put(
        RenderingHints.KEY_INTERPOLATION,
        RenderingHints.VALUE_INTERPOLATION_BICUBIC
      )
      hints.put(
        RenderingHints.KEY_TEXT_ANTIALIASING,
        RenderingHints.VALUE_TEXT_ANTIALIAS_ON
      )
      hints.put(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON)
      renderer.setRenderingHints(hints)
      renderer.setSubsamplingAllowed(enableSubsampling(pdoc.getPage(page)))
      logger.debug(s"Converting pdf page $page to image at dpi $dpi")
      Option(renderer.renderImageWithDPI(page, dpi))
    }
  }

  private def enableSubsampling(page: PDPage): Boolean = {
    val res = page.getResources()
    val largestImage =
      res
        .getXObjectNames()
        .asScala
        .map(name => res.getXObject(name))
        .collect { case xobj: PDImageXObject => xobj }
        .map { imgobj =>
          val w = imgobj.getWidth()
          val h = imgobj.getHeight()
          logger.debug(s"Found image in pdf of size ${w}x${h} (${w * h}px)")
          w * h
        }
        .maxOption
    largestImage.exists(_ > 10 * 1024 * 1024)
  }

  private def pngStream[F[_]](img: RenderedImage): Stream[F, Byte] = {
    val out = new ByteArrayOutputStream()
    ImageIO.write(img, "PNG", out)
    Stream.chunk(Chunk.byteVector(ByteVector.view(out.toByteArray())))
  }
}
