package docspell.ftspsql

import docspell.common._

final case class PsqlConfig(
    url: LenientUri,
    user: String,
    password: Password,
    pgConfigSelect: PartialFunction[Language, String],
    pgQueryParser: PgQueryParser,
    rankNormalization: RankNormalization
)

object PsqlConfig {

  def defaults(url: LenientUri, user: String, password: Password): PsqlConfig =
    PsqlConfig(
      url,
      user,
      password,
      PartialFunction.empty,
      PgQueryParser.Websearch,
      RankNormalization.Mhd && RankNormalization.Scale
    )
}
