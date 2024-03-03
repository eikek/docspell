/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.syntax.all._

import docspell.addons.Middleware
import docspell.backend.auth.AuthToken
import docspell.backend.joex.AddonOps.AddonRunConfigRef
import docspell.common._
import docspell.logging.Logger
import docspell.store.Store
import docspell.store.queries.QLogin
import docspell.store.records.RNode

import scodec.bits.ByteVector

private[joex] class AddonPrepare[F[_]: Sync](store: Store[F]) extends LoggerExtension {

  def logResult(logger: Logger[F], ref: AddonRunConfigRef): Middleware[F] =
    Middleware(
      _.mapF(
        _.attempt
          .flatTap {
            case Right(_) => ().pure[F]
            case Left(ex) =>
              logger
                .withRunConfig(ref)
                .warn(ex)(s"Addon task '${ref.id.id}' has failed")
          }
          .rethrow
      )
    )

  /** Creates environment variables for dsc to connect to the docspell server for the
    * given run config.
    */
  def createDscEnv(
      runConfigRef: AddonRunConfigRef,
      tokenValidity: Duration
  ): F[Middleware[F]] =
    (for {
      userId <- OptionT.fromOption[F](runConfigRef.userId)
      account <- OptionT(store.transact(QLogin.findUser(userId))).map(_.account)
      env =
        Middleware.prepare[F](
          Kleisli(input => makeDscEnv(account, tokenValidity).map(input.addEnv))
        )
    } yield env).getOrElse(Middleware.identity[F])

  /** Creates environment variables to have dsc automatically connect as the given user.
    * Additionally a random rest-server is looked up from the database to set its url.
    */
  def makeDscEnv(
      account: AccountInfo,
      tokenValidity: Duration
  ): F[Map[String, String]] =
    for {
      serverNode <- store.transact(
        RNode
          .findAll(NodeType.Restserver)
          .map(_.sortBy(_.updated).lastOption)
      )
      url = serverNode.map(_.url).map(u => "DSC_DOCSPELL_URL" -> u.asString)
      secret = serverNode.flatMap(_.serverSecret)

      token <- AuthToken.user(
        account,
        requireSecondFactor = false,
        secret.getOrElse(ByteVector.empty),
        tokenValidity.some
      )
      session = ("DSC_SESSION" -> token.asString).some
    } yield List(url, session).flatten.toMap
}
