package docspell.text

import cats.effect.{Blocker, IO}
import docspell.common.LenientUri
import fs2.Stream

import scala.concurrent.ExecutionContext

object TestFiles {
  val blocker     = Blocker.liftExecutionContext(ExecutionContext.global)
  implicit val CS = IO.contextShift(ExecutionContext.global)

  val letterSourceDE: Stream[IO, Byte] =
    LenientUri
      .fromJava(getClass.getResource("/letter-de-source.pdf"))
      .readURL[IO](16 * 1024, blocker)

  val letterSourceEN: Stream[IO, Byte] =
    LenientUri
      .fromJava(getClass.getResource("/letter-en-source.pdf"))
      .readURL[IO](16 * 1024, blocker)

  val letterDEText =
    """Max Mustermann
               |
               |Lilienweg 21
               |
               |12345 Nebendorf
               |
               |E-Mail: max.muster@gmail.com
               |
               |Max Mustermann, Lilienweg 21, 12345 Nebendorf
               |
               |EasyCare AG
               |Abteilung Buchhaltung
               |Ackerweg 12
               |
               |12346 Ulmen
               |
               |Nebendorf, 3. September 2019
               |Sehr geehrte Damen und Herren,
               |
               |hiermit kündige ich meine Mitgliedschaft in der Kranken- und Pflegeversicherung zum
               |nächstmöglichen Termin.
               |
               |Bitte senden Sie mir innerhalb der gesetzlichen Frist von 14 Tagen eine Kündigungsbe-
               |stätigung zu.
               |
               |Vielen Dank im Vorraus!
               |
               |Mit freundlichen Grüßen
               |
               |Max Mustermann
               |""".stripMargin.trim

  val letterENText =
    """Derek Jeter
                       |
                       |123 Elm Ave.
                       |
                       |Treesville, ON MI1N 2P3
                       |November 7, 2016
                       |
                       |Derek Jeter, 123 Elm Ave., Treesville, ON M1N 2P3, November 7, 2016
                       |
                       |Mr. M. Leat
                       |
                       |Chief of Syrup Production
                       |Old Sticky Pancake Company
                       |456 Maple Lane
                       |
                       |Forest, ON 7TW8 9Y0
                       |
                       |Hemptown, September 3, 2019
                       |Dear Mr. Leaf,
                       |
                       |Let me begin by thanking you for your past contributions to our Little League baseball
                       |team. Your sponsorship aided in the purchase of ten full uniforms and several pieces of
                       |baseball equipment for last year’s season.
                       |
                       |Next month, our company is planning an employee appreciation pancake breakfast hon-
                       |oring retired employees for their past years of service and present employees for their
                       |loyalty and dedication in spite of the current difficult economic conditions.
                       |
                       |We would like to place an order with your company for 25 pounds of pancake mix and
                       |five gallons of maple syrup. We hope you will be able to provide these products in the
                       |bulk quantities we require.
                       |
                       |As you are a committed corporate sponsor and long-time associate, we hope that you
                       |will be able to join us for breakfast on December 12, 2016.
                       |
                       |Respectfully yours,
                       |
                       |Derek Jeter
                       |""".stripMargin.trim
}
