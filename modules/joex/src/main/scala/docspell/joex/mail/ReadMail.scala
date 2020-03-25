package docspell.joex.mail

import cats.effect._
import cats.implicits._
import fs2.{Pipe, Stream}
import emil.{MimeType => _, _}
import emil.javamail.syntax._
import emil.tnef.TnefExtract

import docspell.common._
import java.nio.charset.StandardCharsets
import java.nio.charset.Charset
import scodec.bits.ByteVector

object ReadMail {

  def read[F[_]: Sync](str: String): F[Mail[F]] =
    Mail.deserialize(str)

  def readBytesP[F[_]: ConcurrentEffect: ContextShift](
      logger: Logger[F]
  ): Pipe[F, Byte, Binary[F]] =
    _.through(bytesToMail(logger)).flatMap(mailToEntries[F](logger))

  def bytesToMail[F[_]: Sync](logger: Logger[F]): Pipe[F, Byte, Mail[F]] =
    s =>
      Stream.eval(logger.debug(s"Converting e-mail file...")) >>
        s.through(Binary.decode(StandardCharsets.US_ASCII)).foldMonoid.evalMap(read[F])

  def mailToEntries[F[_]: ConcurrentEffect: ContextShift](
      logger: Logger[F]
  )(mail: Mail[F]): Stream[F, Binary[F]] = {
    val bodyEntry: F[Option[Binary[F]]] = mail.body.fold(
      _ => (None: Option[Binary[F]]).pure[F],
      txt => txt.text.map(c => Binary.text[F]("mail.txt", c.bytes, c.charsetOrUtf8).some),
      html => html.html.map(c => makeHtmlBinary(c).some),
      both => both.html.map(c => makeHtmlBinary(c).some)
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
          .eval(TnefExtract.replace(mail))
          .flatMap(m => Stream.emits(m.attachments.all))
          .map(a =>
            Binary(a.filename.getOrElse("noname"), a.mimeType.toDocspell, a.content)
          ))
  }

  private def makeHtmlBinary[F[_]](cnt: BodyContent): Binary[F] = {
    val c = fixHtml(cnt)
    Binary.html[F]("mail.html", c.bytes, c.charsetOrUtf8)
  }

  private def fixHtml(cnt: BodyContent): BodyContent = {
    val str  = cnt.asString.trim.toLowerCase
    val head = htmlHeader(cnt.charsetOrUtf8)
    if (str.startsWith("<html")) cnt
    else
      cnt match {
        case BodyContent.StringContent(s) =>
          BodyContent(head + s + htmlHeaderEnd)
        case BodyContent.ByteContent(bv, cs) =>
          val begin = ByteVector.view(head.getBytes(cnt.charsetOrUtf8))
          val end   = ByteVector.view(htmlHeaderEnd.getBytes(cnt.charsetOrUtf8))
          BodyContent(begin ++ bv ++ end, cs)
      }
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

  private def htmlHeader(cs: Charset): String =
    s"""<!DOCTYPE html>
       |<html>
       |<head>
       |<meta charset="${cs.name}"/>
       |</head>
       |<body>
       """

  private def htmlHeaderEnd: String =
    "</body></html>"
}
