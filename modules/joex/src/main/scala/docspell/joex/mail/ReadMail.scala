package docspell.joex.mail

import cats.effect._
import cats.implicits._
import fs2.{Pipe, Stream}
import emil.{MimeType => _, _}
import emil.javamail.syntax._
import cats.Applicative

import docspell.common._
import java.nio.charset.StandardCharsets

object ReadMail {

  def read[F[_]: Sync](str: String): F[Mail[F]] =
    Mail.deserialize(str)

  def readBytesP[F[_]: Sync](logger: Logger[F]): Pipe[F, Byte, Binary[F]] =
    s =>
      Stream.eval(logger.debug(s"Converting e-mail into its parts")) >>
        bytesToMail(s).flatMap(mailToEntries[F](logger))

  def bytesToMail[F[_]: Sync](data: Stream[F, Byte]): Stream[F, Mail[F]] =
    data.through(Binary.decode(StandardCharsets.US_ASCII)).foldMonoid.evalMap(read[F])

  def mailToEntries[F[_]: Applicative](
      logger: Logger[F]
  )(mail: Mail[F]): Stream[F, Binary[F]] = {
    val bodyEntry: F[Option[Binary[F]]] = mail.body.fold(
      _ => (None: Option[Binary[F]]).pure[F],
      txt => txt.text.map(c => Binary.text[F]("mail.txt", c).some),
      html => html.html.map(c => Binary.html[F]("mail.html", c).some),
      both => both.html.map(c => Binary.html[F]("mail.html", c).some)
    )

    Stream.eval(
      logger.debug(
        s"E-mail has ${mail.attachments.size} attachments and ${bodyType(mail.body)}"
      )
    ) >>
      (Stream
        .eval(bodyEntry)
        .flatMap(e => Stream.emits(e.toSeq)) ++
        Stream
          .emits(mail.attachments.all)
          .map(a =>
            Binary(a.filename.getOrElse("noname"), a.mimeType.toDocspell, a.content)
          ))
  }

  implicit class MimeTypeConv(m: emil.MimeType) {
    def toDocspell: MimeType =
      MimeType(m.primary, m.sub, m.params)
  }

  private def bodyType[F[_]](body: MailBody[F]): String =
    body.fold(
      _ => "empty-body",
      _ => "text-body",
      _ => "html-body",
      _ => "text-and-html-body"
    )
}
