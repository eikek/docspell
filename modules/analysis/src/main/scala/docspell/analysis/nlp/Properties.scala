/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.nlp

import java.util.{Properties => JProps}

import fs2.io.file.Path

import docspell.analysis.nlp.Properties.Implicits._
import docspell.common._
import docspell.common.syntax.FileSyntax._

object Properties {

  def fromMap(m: Map[String, String]): JProps =
    apply(m.toSeq: _*)

  def apply(ps: (String, String)*): JProps = {
    val p = new JProps()
    for ((k, v) <- ps)
      p.setProperty(k, v)
    p
  }

  def forSettings(settings: StanfordNerSettings): JProps =
    settings match {
      case StanfordNerSettings.Full(lang, highRecall, regexNer) =>
        val regexNerFile = regexNer.map(p => p.absolutePathAsString)
        lang match {
          case Language.German =>
            Properties.nerGerman(regexNerFile, highRecall)
          case Language.English =>
            Properties.nerEnglish(regexNerFile)
          case Language.French =>
            Properties.nerFrench(regexNerFile, highRecall)
        }
      case StanfordNerSettings.RegexOnly(path) =>
        Properties.regexNerOnly(path)
    }

  def nerGerman(regexNerMappingFile: Option[String], highRecall: Boolean): JProps =
    Properties(
      "annotators" -> "tokenize,ssplit,mwt,pos,lemma,ner",
      "tokenize.language" -> "de",
      "mwt.mappingFile" -> "edu/stanford/nlp/models/mwt/german/german-mwt.tsv",
      "pos.model" -> "edu/stanford/nlp/models/pos-tagger/german-ud.tagger",
      "ner.statisticalOnly" -> "true",
      "ner.rulesOnly" -> "false",
      "ner.applyFineGrained" -> "false",
      "ner.applyNumericClassifiers" -> "false", // only english supported, not needed currently
      "ner.useSUTime" -> "false", // only english, unused in docspell
      "ner.language" -> "de",
      "ner.model" -> "edu/stanford/nlp/models/ner/german.distsim.crf.ser.gz,edu/stanford/nlp/models/ner/english.conll.4class.distsim.crf.ser.gz"
    ).withRegexNer(regexNerMappingFile).withHighRecall(highRecall)

  def nerEnglish(regexNerMappingFile: Option[String]): JProps =
    Properties(
      "annotators" -> "tokenize,ssplit,pos,lemma,ner",
      "tokenize.language" -> "en",
      "pos.model" -> "edu/stanford/nlp/models/pos-tagger/english-left3words-distsim.tagger",
      "ner.statisticalOnly" -> "true",
      "ner.rulesOnly" -> "false",
      "ner.applyFineGrained" -> "false",
      "ner.applyNumericClassifiers" -> "false",
      "ner.useSUTime" -> "false",
      "ner.language" -> "en",
      "ner.model" -> "edu/stanford/nlp/models/ner/english.conll.4class.distsim.crf.ser.gz"
    ).withRegexNer(regexNerMappingFile)

  def nerFrench(regexNerMappingFile: Option[String], highRecall: Boolean): JProps =
    Properties(
      "annotators" -> "tokenize,ssplit,mwt,pos,lemma,ner",
      "tokenize.language" -> "fr",
      "mwt.mappingFile" -> "edu/stanford/nlp/models/mwt/french/french-mwt.tsv",
      "mwt.pos.model" -> "edu/stanford/nlp/models/mwt/french/french-mwt.tagger",
      "mwt.statisticalMappingFile" -> "edu/stanford/nlp/models/mwt/french/french-mwt-statistical.tsv",
      "pos.model" -> "edu/stanford/nlp/models/pos-tagger/french-ud.tagger",
      "ner.statisticalOnly" -> "true",
      "ner.rulesOnly" -> "false",
      "ner.applyFineGrained" -> "false",
      "ner.applyNumericClassifiers" -> "false",
      "ner.useSUTime" -> "false",
      "ner.language" -> "de",
      "ner.model" -> "edu/stanford/nlp/models/ner/french-wikiner-4class.crf.ser.gz,edu/stanford/nlp/models/ner/english.conll.4class.distsim.crf.ser.gz"
    ).withRegexNer(regexNerMappingFile).withHighRecall(highRecall)

  def regexNerOnly(regexNerMappingFile: Path): JProps =
    Properties(
      "annotators" -> "tokenize,ssplit"
    ).withRegexNer(Some(regexNerMappingFile.absolutePathAsString))

  object Implicits {
    implicit final class JPropsOps(val p: JProps) extends AnyVal {

      def set(name: String, value: Option[String]): JProps =
        value match {
          case Some(v) =>
            p.setProperty(name, v)
            p
          case None =>
            p
        }

      def change(name: String, f: String => String): JProps =
        Option(p.getProperty(name)) match {
          case Some(current) =>
            p.setProperty(name, f(current))
            p
          case None =>
            p
        }

      def withRegexNer(mappingFile: Option[String]): JProps =
        set("regexner.mapping", mappingFile)
          .change(
            "annotators",
            v => if (mappingFile.isDefined) v + ",regexner" else v
          )

      def withHighRecall(flag: Boolean): JProps = {
        if (flag) p.setProperty("ner.combinationMode", "HIGH_RECALL")
        else p.setProperty("ner.combinationMode", "NORMAL")
        p
      }
    }
  }
}
