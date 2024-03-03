/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.routes

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.restapi.model._

import com.github.eikek.calev.CalEvent
import org.http4s._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.circe.CirceEntityEncoder._
import org.http4s.dsl.Http4sDsl

object CalEventCheckRoutes {

  def apply[F[_]: Async](): HttpRoutes[F] = {
    val dsl = new Http4sDsl[F] {}
    import dsl._

    HttpRoutes.of { case req @ POST -> Root =>
      for {
        data <- req.as[CalEventCheck]
        res <- testEvent(data.event)
        resp <- Ok(res)
      } yield resp
    }
  }

  def testEvent[F[_]: Sync](str: String): F[CalEventCheckResult] =
    Timestamp.current[F].map { now =>
      CalEvent.parse(str) match {
        case Right(ev) =>
          val next = ev
            .nextElapses(now.toUtcDateTime, 2)
            .map(Timestamp.atUtc)
          CalEventCheckResult(success = true, "Valid.", ev.some, next)
        case Left(err) =>
          CalEventCheckResult(success = false, err, None, Nil)
      }
    }
}
