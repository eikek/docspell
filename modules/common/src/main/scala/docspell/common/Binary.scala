package docspell.common

import fs2.Stream

final case class Binary[F[_]](name: String, mime: MimeType, data: Stream[F, Byte]) {

  def withMime(mime: MimeType): Binary[F] =
    copy(mime = mime)
}

object Binary {

  def apply[F[_]](name: String, data: Stream[F, Byte]): Binary[F] =
    Binary[F](name, MimeType.octetStream, data)

  def utf8[F[_]](name: String, content: String): Binary[F] =
    Binary[F](name, MimeType.octetStream, Stream.emit(content).through(fs2.text.utf8Encode))

  def text[F[_]](name: String, content: String): Binary[F] =
    utf8(name, content).withMime(MimeType.plain)

  def html[F[_]](name: String, content: String): Binary[F] =
    utf8(name, content).withMime(MimeType.html)
}
