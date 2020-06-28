package docspell.store.records

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import bitpeace.FileMeta
import doobie._
import doobie.implicits._

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

  def findById(fid: Ident): ConnectionIO[Option[FileMeta]] = {
    import bitpeace.sql._

    selectSimple(Columns.all, table, Columns.id.is(fid)).query[FileMeta].option
  }
}
