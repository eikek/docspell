/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

sealed trait NodeType { self: Product =>

  final def name: String =
    self.productPrefix.toLowerCase

}

object NodeType {

  case object Restserver extends NodeType
  case object Joex       extends NodeType

  def fromString(str: String): Either[String, NodeType] =
    str.toLowerCase match {
      case "restserver" => Right(Restserver)
      case "joex"       => Right(Joex)
      case _            => Left(s"Invalid node type: $str")
    }

  def unsafe(str: String): NodeType =
    fromString(str).fold(sys.error, identity)

}
