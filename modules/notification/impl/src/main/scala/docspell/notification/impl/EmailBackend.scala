/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.notification.api._

import emil.Emil
import emil.markdown.MarkdownBody

final class EmailBackend[F[_]: Sync](
    channel: NotificationChannel.Email,
    mailService: Emil[F],
    logger: Logger[F]
) extends NotificationBackend[F] {

  import emil.builder._

  def send(event: EventContext): F[Unit] = {
    val mail =
      MailBuilder.build(
        From(channel.from),
        Tos(channel.recipients.toList),
        Subject(event.defaultTitle),
        MarkdownBody[F](event.defaultBody)
      )

    logger.debug(s"Attempting to send notification mail: $channel") *>
      mailService(channel.config)
        .send(mail)
        .flatMap(msgId => logger.info(s"Send notification mail ${msgId.head}"))
  }
}
