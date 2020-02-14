package docspell.examplefiles

import docspell.common._

trait ExampleFilesSupport {

  def createUrl(resource: String): LenientUri =
    Option(getClass.getResource("/" + resource)) match {
      case Some(u) => LenientUri.fromJava(u)
      case None => sys.error(s"Resource '$resource' not found")
    }


}
