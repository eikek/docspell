/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.totp

import java.time.Instant

import fs2.Stream

import com.eatthepath.otp.TimeBasedOneTimePasswordGenerator

/** Generator for time based one time passwords. */
trait Totp {

  /** The settings used to generate passwords. */
  def settings: Settings

  /** Generate the password for the given key and time. */
  def generate(key: Key, time: Instant): OnetimePassword

  /** Generate a stream of passwords using the given key and starting at the given time.
    */
  def generateStream[F[_]](key: Key, time: Instant): Stream[F, OnetimePassword]

  /** Checks whether the given password matches using the current time. */
  def checkPassword(key: Key, otp: OnetimePassword, time: Instant): Boolean
}

object Totp {

  val default: Totp =
    Totp(Settings.default)

  def apply(setts: Settings): Totp =
    new Totp {

      val settings = setts
      private val generator = makeGenerator(setts)

      def generate(key: Key, time: Instant): OnetimePassword =
        OnetimePassword(generator.generateOneTimePasswordString(key.toJavaKey, time))

      def generateStream[F[_]](key: Key, time: Instant): Stream[F, OnetimePassword] =
        Stream.emit(generate(key, time)) ++ generateStream(
          key,
          time.plus(generator.getTimeStep)
        )

      def checkPassword(key: Key, givenPass: OnetimePassword, time: Instant): Boolean = {
        val pass = generate(key, time)
        pass == givenPass
      }
    }

  private def makeGenerator(settings: Settings): TimeBasedOneTimePasswordGenerator = {
    val duration = java.time.Duration.ofNanos(settings.duration.toNanos)
    new TimeBasedOneTimePasswordGenerator(
      duration,
      settings.passLength.toInt,
      settings.mac.identifier
    )
  }
}
