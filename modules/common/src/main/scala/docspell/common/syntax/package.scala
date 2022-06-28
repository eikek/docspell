/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

package object syntax {

  val either = EitherSyntax
  val stream = StreamSyntax
  val string = StringSyntax
  val file = FileSyntax

  object all extends EitherSyntax with StreamSyntax with StringSyntax with FileSyntax

}
