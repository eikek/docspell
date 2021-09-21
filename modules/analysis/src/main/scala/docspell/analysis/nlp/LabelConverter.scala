/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.nlp

import docspell.common.{NerLabel, NerTag}

import edu.stanford.nlp.ling.{CoreAnnotation, CoreAnnotations, CoreLabel}

object LabelConverter {

  private def tagFromLabel[A <: CoreAnnotation[String]](
      label: CoreLabel,
      annot: Class[A]
  ): Option[NerTag] = {
    val tag = label.get(annot)
    Option(tag).flatMap(s => NerTag.fromString(s).toOption)
  }

  def findTag(label: CoreLabel): Option[NerTag] =
    tagFromLabel(label, classOf[CoreAnnotations.AnswerAnnotation])
      .orElse(tagFromLabel(label, classOf[CoreAnnotations.NamedEntityTagAnnotation]))

  def toNerLabel(label: CoreLabel): Option[NerLabel] =
    findTag(label).map(t =>
      NerLabel(label.word(), t, label.beginPosition(), label.endPosition())
    )
}
