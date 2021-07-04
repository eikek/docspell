/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.files

case class Dimension(width: Int, height: Int) {

  def product = width * height

  def toAwtDimension: java.awt.Dimension =
    new java.awt.Dimension(width, height)
}
