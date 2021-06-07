package docspell.ftssolr

final case class VersionDoc(id: String, currentVersion: Int)

object VersionDoc {

  object Fields {
    val id             = Field("id")
    val currentVersion = Field("current_version_i")
  }
}
