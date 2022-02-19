/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

package object syntax {

  object all extends EitherSyntax with StreamSyntax with StringSyntax with FileSyntax

}
