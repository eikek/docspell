/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.nlp

import java.nio.file.Paths

import cats.effect.IO
import cats.effect.unsafe.implicits.global

import docspell.analysis.Env
import docspell.common._
import docspell.common.util.File
import docspell.files.TestFiles
import docspell.logging.TestLoggingConfig

import edu.stanford.nlp.pipeline.StanfordCoreNLP
import munit._

class StanfordNerAnnotatorSuite extends FunSuite with TestLoggingConfig {
  lazy val germanClassifier =
    new StanfordCoreNLP(Properties.nerGerman(None, highRecall = false))
  lazy val englishClassifier =
    new StanfordCoreNLP(Properties.nerEnglish(None))

  test("find english ner labels") {
    assume(!Env.isCI, "Test ignored on travis.")

    val labels =
      StanfordNerAnnotator.nerAnnotate(englishClassifier, TestFiles.letterENText)
    val expect = Vector(
      NerLabel("Derek", NerTag.Person, 0, 5),
      NerLabel("Jeter", NerTag.Person, 6, 11),
      NerLabel("Elm", NerTag.Misc, 17, 20),
      NerLabel("Ave.", NerTag.Misc, 21, 25),
      NerLabel("Treesville", NerTag.Misc, 27, 37),
      NerLabel("Derek", NerTag.Person, 68, 73),
      NerLabel("Jeter", NerTag.Person, 74, 79),
      NerLabel("Elm", NerTag.Misc, 85, 88),
      NerLabel("Ave.", NerTag.Misc, 89, 93),
      NerLabel("Treesville", NerTag.Person, 95, 105),
      NerLabel("Leaf", NerTag.Organization, 144, 148),
      NerLabel("Chief", NerTag.Organization, 150, 155),
      NerLabel("of", NerTag.Organization, 156, 158),
      NerLabel("Syrup", NerTag.Organization, 159, 164),
      NerLabel("Production", NerTag.Organization, 165, 175),
      NerLabel("Old", NerTag.Organization, 176, 179),
      NerLabel("Sticky", NerTag.Organization, 180, 186),
      NerLabel("Pancake", NerTag.Organization, 187, 194),
      NerLabel("Company", NerTag.Organization, 195, 202),
      NerLabel("Maple", NerTag.Organization, 207, 212),
      NerLabel("Lane", NerTag.Organization, 213, 217),
      NerLabel("Forest", NerTag.Organization, 219, 225),
      NerLabel("Hemptown", NerTag.Location, 239, 247),
      NerLabel("Leaf", NerTag.Person, 276, 280),
      NerLabel("Little", NerTag.Misc, 347, 353),
      NerLabel("League", NerTag.Misc, 354, 360),
      NerLabel("Derek", NerTag.Person, 1117, 1122),
      NerLabel("Jeter", NerTag.Person, 1123, 1128)
    )
    assertEquals(labels, expect)
    StanfordCoreNLP.clearAnnotatorPool()
  }

  test("find german ner labels") {
    assume(!Env.isCI, "Test ignored on travis.")

    val labels =
      StanfordNerAnnotator.nerAnnotate(germanClassifier, TestFiles.letterDEText)
    val expect = Vector(
      NerLabel("Max", NerTag.Person, 0, 3),
      NerLabel("Mustermann", NerTag.Person, 4, 14),
      NerLabel("Lilienweg", NerTag.Person, 16, 25),
      NerLabel("Max", NerTag.Person, 77, 80),
      NerLabel("Mustermann", NerTag.Person, 81, 91),
      NerLabel("Lilienweg", NerTag.Location, 93, 102),
      NerLabel("EasyCare", NerTag.Organization, 124, 132),
      NerLabel("AG", NerTag.Organization, 133, 135),
      NerLabel("Ackerweg", NerTag.Location, 158, 166),
      NerLabel("Nebendorf", NerTag.Location, 184, 193),
      NerLabel("Max", NerTag.Person, 505, 508),
      NerLabel("Mustermann", NerTag.Person, 509, 519)
    )
    assertEquals(labels, expect)
    StanfordCoreNLP.clearAnnotatorPool()
  }

  test("regexner-only annotator") {
    assume(!Env.isCI, "Test ignored on travis.")

    val regexNerContent =
      s"""(?i)volantino ag${"\t"}ORGANIZATION${"\t"}LOCATION,PERSON,MISC${"\t"}3
         |(?i)volantino${"\t"}ORGANIZATION${"\t"}LOCATION,PERSON,MISC${"\t"}3
         |(?i)ag${"\t"}ORGANIZATION${"\t"}LOCATION,PERSON,MISC${"\t"}3
         |(?i)andrea rossi${"\t"}PERSON${"\t"}LOCATION,MISC${"\t"}2
         |(?i)andrea${"\t"}PERSON${"\t"}LOCATION,MISC${"\t"}2
         |(?i)rossi${"\t"}PERSON${"\t"}LOCATION,MISC${"\t"}2
         |""".stripMargin

    File
      .withTempDir[IO](File.path(Paths.get("target")), "test-regex-ner")
      .use { dir =>
        for {
          out <- File.writeString[IO](dir / "regex.txt", regexNerContent)
          ann = StanfordNerAnnotator.makePipeline(StanfordNerSettings.RegexOnly(out))
          labels = StanfordNerAnnotator.nerAnnotate(ann, "Hello Andrea Rossi, can you.")
          _ <- IO(
            assertEquals(
              labels,
              Vector(
                NerLabel("Andrea", NerTag.Person, 6, 12),
                NerLabel("Rossi", NerTag.Person, 13, 18)
              )
            )
          )
        } yield ()
      }
      .unsafeRunSync()
    StanfordCoreNLP.clearAnnotatorPool()
  }
}
