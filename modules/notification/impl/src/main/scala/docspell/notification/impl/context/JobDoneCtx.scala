/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

import cats.effect._

import docspell.common._
import docspell.notification.api._
import docspell.notification.impl.AbstractEventContext

import doobie._
import io.circe.syntax._
import io.circe.{Encoder, Json}
import yamusca.implicits._

final case class JobDoneCtx(event: Event.JobDone, data: JobDoneCtx.Data)
    extends AbstractEventContext {

  val content = data.asJson

  val titleTemplate = Right(mustache"{{eventType}} (by *{{account.user}}*)")
  val bodyTemplate =
    data.resultMsg match {
      case None =>
        Right(mustache"""{{#content}}_'{{subject}}'_ finished {{/content}}""")
      case Some(msg) =>
        val tpl = s"""{{#content}}$msg{{/content}}"""
        yamusca.imports.mustache.parse(tpl).left.map(_._2)
    }
}

object JobDoneCtx {

  type Factory = EventContext.Factory[ConnectionIO, Event.JobDone]

  def apply: Factory =
    EventContext.pure(ev => JobDoneCtx(ev, Data(ev)))

  def sample[F[_]: Sync]: EventContext.Example[F, Event.JobDone] =
    EventContext.example(ev => Sync[F].pure(JobDoneCtx(ev, Data(ev))))

  final case class Data(
      job: Ident,
      group: Ident,
      task: Ident,
      args: String,
      state: JobState,
      subject: String,
      submitter: Ident,
      resultData: Json,
      resultMsg: Option[String]
  )
  object Data {
    implicit val jsonEncoder: Encoder[Data] =
      io.circe.generic.semiauto.deriveEncoder

    def apply(ev: Event.JobDone): Data =
      Data(
        ev.jobId,
        ev.group,
        ev.task,
        ev.args,
        ev.state,
        ev.subject,
        ev.submitter,
        ev.resultData,
        ev.resultMsg
      )
  }
}
