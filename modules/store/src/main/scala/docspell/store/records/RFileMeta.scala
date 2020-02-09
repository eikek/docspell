package docspell.store.records

import doobie.implicits._
import docspell.store.impl._

object RFileMeta {

  val table = fr"filemeta"

  object Columns {
    val id        = Column("id")
    val timestamp = Column("timestamp")
    val mimetype  = Column("mimetype")
    val length    = Column("length")
    val checksum  = Column("checksum")
    val chunks    = Column("chunks")
    val chunksize = Column("chunksize")

    val all = List(id, timestamp, mimetype, length, checksum, chunks, chunksize)

  }
}
