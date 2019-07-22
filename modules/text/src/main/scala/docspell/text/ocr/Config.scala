package docspell.text.ocr

import java.nio.file.{Path, Paths}

import docspell.common._

case class Config(
  allowedContentTypes: Set[MimeType]
    , ghostscript: Config.Ghostscript
    , pageRange: Config.PageRange
    , unpaper: Config.Unpaper
    , tesseract: Config.Tesseract
) {

  def isAllowed(mt: MimeType): Boolean =
    allowedContentTypes contains mt
}

object Config {
  case class PageRange(begin: Int)

  case class Command(program: String, args: Seq[String], timeout: Duration) {

    def mapArgs(f: String => String): Command =
      Command(program, args map f, timeout)

    def toCmd: List[String] =
      program :: args.toList

    lazy val cmdString: String =
      toCmd.mkString(" ")
  }

  case class Ghostscript(command: Command, workingDir: Path)
  case class Tesseract(command: Command)
  case class Unpaper(command: Command)

  val default = Config(
    allowedContentTypes = Set(
      MimeType.pdf,
      MimeType.png,
      MimeType.jpeg,
      MimeType.tiff
    ),
    pageRange = PageRange(10),
    ghostscript = Ghostscript(
      Command("gs", Seq("-dNOPAUSE"
        , "-dBATCH"
        , "-dSAFER"
        , "-sDEVICE=tiffscaled8"
        , "-sOutputFile={{outfile}}"
        , "{{infile}}"),
      Duration.seconds(30)),
      Paths.get(System.getProperty("java.io.tmpdir")).
        resolve("docspell-extraction")),
    unpaper = Unpaper(Command("unpaper"
      , Seq("{{infile}}", "{{outfile}}")
      , Duration.seconds(30))),
    tesseract = Tesseract(
      Command("tesseract", Seq("{{file}}"
        , "stdout"
        , "-l"
        , "{{lang}}"),
      Duration.minutes(1)))
  )
}
