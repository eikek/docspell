/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

sealed trait Operator

object Operator {

  case object Eq extends Operator
  case object LowerEq extends Operator
  case object Neq extends Operator
  case object Gt extends Operator
  case object Lt extends Operator
  case object Gte extends Operator
  case object Lte extends Operator
  case object LowerLike extends Operator

}
