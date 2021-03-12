package docspell.common

import cats.implicits._
import munit._

class LenientUriTest extends FunSuite {

  test("do not throw on invalid hex decoding") {
    assert(LenientUri.parse("h:%x39005").isLeft)
  }

  test("percent-decode invalid codes") {
    assertEquals(LenientUri.percentDecode("h:%x39-2"), None)
  }

  test("percent-decode valid codes") {
    assertEquals(LenientUri.percentDecode("a%20b"), "a b".some)
    assertEquals(LenientUri.percentDecode("a%3Fb"), "a?b".some)
    assertEquals(
      LenientUri.percentDecode("0%2F%3A%7B%7D%29%28%3A-%2F%29%7D-%7B%2F%7D"),
      "0/:{})(:-/)}-{/}".some
    )
    assertEquals(LenientUri.percentDecode("a%25b%5Cc%7Cd%23e"), "a%b\\c|d#e".some)
  }
}
