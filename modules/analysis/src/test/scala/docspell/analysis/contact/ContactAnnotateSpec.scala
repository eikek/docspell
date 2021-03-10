package docspell.analysis.contact

import docspell.common.{NerLabel, NerTag}
import munit._

class ContactAnnotateSpec extends FunSuite {

  test("find email") {

    val text =
      """An email address such as John.Smith@example.com is made up
        |of a local-part, an @ symbol, then a case-insensitive domain.
        |Although the standard requires[1] the local part to be
        |case-sensitive, it also urges that receiving hosts deliver
        |messages in a case-independent fashion,[2] e.g., that the mail
        |system at example.com treat John.Smith as equivalent to
        |john.smith; some mail systems even treat them as equivalent
        |to johnsmith.[3] Mail systems often limit their users' choice
        |of name to a subset of the technically valid characters, and
        |in some cases also limit which addresses it is possible to
        |send mail to.""".stripMargin

    val labels = Contact.annotate(text)
    assertEquals(labels.size, 2)
    assertEquals(labels(0), NerLabel("john.smith@example.com", NerTag.Email, 25, 47))
    assertEquals(text.substring(25, 47).toLowerCase, "john.smith@example.com")
    assertEquals(labels(1), NerLabel("example.com", NerTag.Website, 308, 319))
    assertEquals(text.substring(308, 319).toLowerCase, "example.com")
  }
}
