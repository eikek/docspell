/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

final case class NerLabelSpan private (
    labels: Vector[NerLabel]
) {

  def size: Int = labels.size

  def +(label: NerLabel): NerLabelSpan =
    labels.lastOption match {
      case None =>
        NerLabelSpan(Vector(label))
      case Some(el) =>
        if (label.startPosition - el.endPosition == 1) NerLabelSpan(labels :+ label)
        else this
    }

  def asLabel: Option[NerLabel] =
    (labels.headOption, labels.lastOption) match {
      case (Some(s), Some(e)) =>
        Some(
          NerLabel(
            labels.map(_.label).mkString(" "),
            s.tag,
            s.startPosition,
            e.endPosition
          )
        )
      case _ =>
        None
    }
}

object NerLabelSpan {

  val empty = NerLabelSpan(Vector.empty)

  def buildSpans(labels: Seq[NerLabel]): Vector[NerLabelSpan] = {
    val sorted = labels.sortBy(_.startPosition)
    sorted
      .foldLeft(Vector.empty[NerLabelSpan]) { (span, el) =>
        span.lastOption match {
          case Some(last) =>
            val next = last + el
            if (next eq last) span :+ (empty + el)
            else span.dropRight(1) :+ next
          case None =>
            Vector(empty + el)
        }
      }
      .filter(_.size > 1)
  }

  def build(labels: Seq[NerLabel]): Vector[NerLabel] =
    buildSpans(labels).flatMap(_.asLabel)
}
