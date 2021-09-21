/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import java.io.{ByteArrayInputStream, InputStream}
import javax.imageio.stream.{FileImageInputStream, ImageInputStream}
import javax.imageio.{ImageIO, ImageReader}

import scala.jdk.CollectionConverters._
import scala.util.{Try, Using}

import cats.effect._
import cats.implicits._
import fs2.Stream
import fs2.io.file.Path

object ImageSize {

  /** Return the image size from its header without reading the whole image into memory.
    */
  def get(file: Path): Option[Dimension] =
    Using(new FileImageInputStream(file.toNioPath.toFile))(getDimension).toOption.flatten

  /** Return the image size from its header without reading the whole image into memory.
    */
  def get(in: InputStream): Option[Dimension] =
    Option(ImageIO.createImageInputStream(in)).flatMap(getDimension)

  /** Return the image size from its header without reading the whole image into memory.
    */
  def get[F[_]: Sync](data: Stream[F, Byte]): F[Option[Dimension]] =
    data.take(768).compile.to(Array).map { ar =>
      val iis = ImageIO.createImageInputStream(new ByteArrayInputStream(ar))
      if (iis == null) sys.error("no reader given for the array")
      else getDimension(iis)
    }

  private def getDimension(in: ImageInputStream): Option[Dimension] =
    ImageIO
      .getImageReaders(in)
      .asScala
      .to(LazyList)
      .collectFirst(Function.unlift { reader =>
        val dim = getDimension(in, reader).toOption
        reader.dispose()
        dim
      })

  private def getDimension(
      in: ImageInputStream,
      reader: ImageReader
  ): Either[Throwable, Dimension] =
    Try {
      reader.setInput(in)
      val width  = reader.getWidth(reader.getMinIndex)
      val height = reader.getHeight(reader.getMinIndex)
      Dimension(width, height)
    }.toEither
}
