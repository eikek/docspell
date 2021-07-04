/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

package object syntax {

  object all
      extends EitherSyntax
      with StreamSyntax
      with StringSyntax
      with LoggerSyntax
      with FileSyntax

}
