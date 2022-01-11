package docspell.notification.impl

import docspell.notification.api.EventContext
import docspell.common.Logger
import io.circe.Json

trait EventContextSyntax {
  private def logError[F[_]](logger: Logger[F])(reason: String): F[Unit] =
    logger.error(s"Unable to send notification, the template failed to render: $reason")

  implicit final class EventContextOps(self: EventContext) {
    def withDefault[F[_]](logger: Logger[F])(f: (String, String) => F[Unit]): F[Unit] =
      (for {
        tt <- self.defaultTitle
        tb <- self.defaultBody
      } yield f(tt, tb)).fold(logError(logger), identity)

    def withJsonMessage[F[_]](logger: Logger[F])(f: Json => F[Unit]): F[Unit] =
      self.asJsonWithMessage match {
        case Right(m)  => f(m)
        case Left(err) => logError(logger)(err)
      }

    def withDefaultBoth[F[_]](logger: Logger[F])(f: (String, String) => F[Unit]): F[Unit] =
      (for {
        md <- self.defaultBoth
        html <- self.defaultBothHtml
      } yield f(md, html)).fold(logError(logger), identity)
  }
}
