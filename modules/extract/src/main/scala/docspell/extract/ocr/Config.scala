package docspell.extract.ocr

import java.nio.file.{Path, Paths}

import docspell.common._

case class Config(
    allowedContentTypes: Set[MimeType],
    ghostscript: Config.Ghostscript,
    pageRange: Config.PageRange,
    unpaper: Config.Unpaper,
    tesseract: Config.Tesseract
) {

  def isAllowed(mt: MimeType): Boolean =
    allowedContentTypes contains mt
}

object Config {
  case class PageRange(begin: Int)

  case class Ghostscript(command: SystemCommand.Config, workingDir: Path)
  case class Tesseract(command: SystemCommand.Config)
  case class Unpaper(command: SystemCommand.Config)

  val default = Config(
    allowedContentTypes = Set(
      MimeType.pdf,
      MimeType.png,
      MimeType.jpeg,
      MimeType.tiff
    ),
    pageRange = PageRange(10),
    ghostscript = Ghostscript(
      SystemCommand.Config(
        "gs",
        Seq(
          "-dNOPAUSE",
          "-dBATCH",
          "-dSAFER",
          "-sDEVICE=tiffscaled8",
          "-sOutputFile={{outfile}}",
          "{{infile}}"
        ),
        Duration.seconds(30)
      ),
      Paths.get(System.getProperty("java.io.tmpdir")).resolve("docspell-extraction")
    ),
    unpaper = Unpaper(SystemCommand.Config("unpaper", Seq("{{infile}}", "{{outfile}}"), Duration.seconds(30))),
    tesseract = Tesseract(
      SystemCommand.Config("tesseract", Seq("{{file}}", "stdout", "-l", "{{lang}}"), Duration.minutes(1))
    )
  )
}
