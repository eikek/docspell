package docspell.ftspsql

import docspell.common.{LenientUri, Password}

case class PsqlConfig(url: LenientUri, user: String, password: Password)
