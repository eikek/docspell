/*
 * Copyright (c) 2021 Typelevel
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package docspell.query.internal

// modified, from
// https://github.com/typelevel/cats-parse/blob/e7a58ef15925358fbe7a4c0c1a204296e366a06c/bench/src/main/scala/cats/parse/bench/self.scala
import cats.parse.{Parser => P, Parser0 => P0}

object StringUtil {

  def quoted(q: Char): P[String] =
    Util.escapedString(q)

  private object Util extends GenericStringUtil {
    lazy val decodeTable: Map[Char, Char] =
      Map(
        ('\\', '\\'),
        ('\'', '\''),
        ('\"', '\"'),
        ('n', '\n'),
        ('r', '\r'),
        ('t', '\t')
      )
  }
  abstract private class GenericStringUtil {
    protected def decodeTable: Map[Char, Char]

    private val encodeTable = decodeTable.iterator.map { case (v, k) =>
      (k, s"\\$v")
    }.toMap

    private val nonPrintEscape: Array[String] =
      (0 until 32).map { c =>
        val strHex = c.toHexString
        val strPad = List.fill(4 - strHex.length)('0').mkString
        s"\\u$strPad$strHex"
      }.toArray

    val escapedToken: P[Unit] = {
      val escapes = P.charIn(decodeTable.keys.toSeq)

      val oct = P.charIn('0' to '7')
      val octP = P.char('o') ~ oct ~ oct

      val hex = P.charIn(('0' to '9') ++ ('a' to 'f') ++ ('A' to 'F'))
      val hex2 = hex ~ hex
      val hexP = P.char('x') ~ hex2

      val hex4 = hex2 ~ hex2
      val u4 = P.char('u') ~ hex4
      val hex8 = hex4 ~ hex4
      val u8 = P.char('U') ~ hex8

      val after = P.oneOf[Any](escapes :: octP :: hexP :: u4 :: u8 :: Nil)
      (P.char('\\') ~ after).void
    }

    /** String content without the delimiter */
    def undelimitedString(endP: P[Unit]): P[String] =
      escapedToken.backtrack
        .orElse((!endP).with1 ~ P.anyChar)
        .rep
        .string
        .flatMap { str =>
          unescape(str) match {
            case Right(str1) => P.pure(str1)
            case Left(_)     => P.fail
          }
        }

    private val simpleString: P0[String] =
      P.charsWhile0(c => c >= ' ' && c != '"' && c != '\\')

    def escapedString(q: Char): P[String] = {
      val end: P[Unit] = P.char(q)
      end *> ((simpleString <* end).backtrack
        .orElse(undelimitedString(end) <* end))
    }

    def escape(quoteChar: Char, str: String): String = {
      // We can ignore escaping the opposite character used for the string
      // x isn't escaped anyway and is kind of a hack here
      val ignoreEscape =
        if (quoteChar == '\'') '"' else if (quoteChar == '"') '\'' else 'x'
      str.flatMap { c =>
        if (c == ignoreEscape) c.toString
        else
          encodeTable.get(c) match {
            case None =>
              if (c < ' ') nonPrintEscape(c.toInt)
              else c.toString
            case Some(esc) => esc
          }
      }
    }

    def unescape(str: String): Either[Int, String] = {
      val sb = new java.lang.StringBuilder
      def decodeNum(idx: Int, size: Int, base: Int): Int = {
        val end = idx + size
        if (end <= str.length) {
          val intStr = str.substring(idx, end)
          val asInt =
            try Integer.parseInt(intStr, base)
            catch { case _: NumberFormatException => ~idx }
          sb.append(asInt.toChar)
          end
        } else ~str.length
      }
      @annotation.tailrec
      def loop(idx: Int): Int =
        if (idx >= str.length) {
          // done
          idx
        } else if (idx < 0) {
          // error from decodeNum
          idx
        } else {
          val c0 = str.charAt(idx)
          if (c0 != '\\') {
            sb.append(c0)
            loop(idx + 1)
          } else {
            // str(idx) == \
            val nextIdx = idx + 1
            if (nextIdx >= str.length) {
              // error we expect there to be a character after \
              ~idx
            } else {
              val c = str.charAt(nextIdx)
              decodeTable.get(c) match {
                case Some(d) =>
                  sb.append(d)
                  loop(idx + 2)
                case None =>
                  c match {
                    case 'o'   => loop(decodeNum(idx + 2, 2, 8))
                    case 'x'   => loop(decodeNum(idx + 2, 2, 16))
                    case 'u'   => loop(decodeNum(idx + 2, 4, 16))
                    case 'U'   => loop(decodeNum(idx + 2, 8, 16))
                    case other =>
                      // \c is interpreted as just \c, if the character isn't escaped
                      sb.append('\\')
                      sb.append(other)
                      loop(idx + 2)
                  }
              }
            }
          }
        }

      val res = loop(0)
      if (res < 0) Left(~res)
      else Right(sb.toString)
    }
  }

}
