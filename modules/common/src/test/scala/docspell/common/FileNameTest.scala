package docspell.common

import minitest._

object FileNameTest extends SimpleTestSuite {

  test("make filename") {
    val data = List(
      (FileName("test"), "test", None),
      (FileName("test.pdf"), "test", Some("pdf")),
      (FileName("bla.xml.gz"), "bla.xml", Some("gz")),
      (FileName(""), "unknown-file", None)
    )

    data.foreach { case (fn, base, ext) =>
      assertEquals(fn.baseName, base)
      assertEquals(fn.extension, ext)
    }
  }

  test("with part") {
    assertEquals(
      FileName("test.pdf").withPart("converted", '_'),
      FileName("test_converted.pdf")
    )
    assertEquals(
      FileName("bla.xml.gz").withPart("converted", '_'),
      FileName("bla.xml_converted.gz")
    )
    assertEquals(
      FileName("test").withPart("converted", '_'),
      FileName("test_converted")
    )
    assertEquals(
      FileName("test").withPart("", '_'),
      FileName("test")
    )
  }

  test("with extension") {
    assertEquals(
      FileName("test.pdf").withExtension("xml"),
      FileName("test.xml")
    )
    assertEquals(
      FileName("test").withExtension("xml"),
      FileName("test.xml")
    )
    assertEquals(
      FileName("test.pdf.gz").withExtension("xml"),
      FileName("test.pdf.xml")
    )
    assertEquals(
      FileName("test.pdf.gz").withExtension(""),
      FileName("test.pdf")
    )
  }
}
