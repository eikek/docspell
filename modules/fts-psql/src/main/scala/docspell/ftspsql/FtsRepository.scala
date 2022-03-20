package docspell.ftspsql

import cats.data.NonEmptyList
import docspell.common._
import docspell.ftsclient.FtsQuery
import doobie._
import doobie.implicits._
import fs2.Chunk

object FtsRepository extends DoobieMeta {
  val table = fr"ftspsql_search"

  def searchSummary(q: FtsQuery): ConnectionIO[SearchSummary] = {
    val selectRank = mkSelectRank
    val query = mkQueryPart(q)

    sql"""select count(id), max($selectRank)
         |from $table, $query
         |where ${mkCondition(q)} AND query @@ text_index 
         |""".stripMargin
      .query[SearchSummary]
      .unique
  }

  def search(
      q: FtsQuery,
      withHighlighting: Boolean
  ): ConnectionIO[Vector[SearchResult]] = {
    val selectRank = mkSelectRank

    val hlOption =
      s"startsel=${q.highlight.pre},stopsel=${q.highlight.post}"

    val selectHl =
      if (!withHighlighting) fr"null as highlight"
      else
        fr"""ts_headline(
            |    fts_config,
            |    coalesce(attach_name, '') ||
            |    ' ' || coalesce(attach_content, '') ||
            |    ' ' || coalesce(item_name, '') ||
            |    ' ' || coalesce(item_notes, ''), query, $hlOption) as highlight""".stripMargin

    val select =
      fr"id, item_id, collective, lang, attach_id, folder_id, attach_name, item_name, $selectRank as rank, $selectHl"

    val query = mkQueryPart(q)

    sql"""select $select 
         |from $table, $query
         |where ${mkCondition(q)} AND query @@ text_index 
         |order by rank desc
         |limit ${q.limit}
         |offset ${q.offset}
         |""".stripMargin
      .query[SearchResult]
      .to[Vector]
  }

  private def mkCondition(q: FtsQuery): Fragment = {
    val coll = fr"collective = ${q.collective}"
    val items =
      NonEmptyList.fromList(q.items.toList).map { nel =>
        val ids = nel.map(id => fr"$id").reduceLeft(_ ++ fr"," ++ _)
        fr"item_id in ($ids)"
      }

    val folders =
      NonEmptyList.fromList(q.folders.toList).map { nel =>
        val ids = nel.map(id => fr"$id").reduceLeft(_ ++ fr"," ++ _)
        fr"folder_id in ($ids)"
      }

    List(items, folders).flatten.foldLeft(coll)(_ ++ fr"AND" ++ _)
  }

  private def mkQueryPart(q: FtsQuery): Fragment =
    fr"websearch_to_tsquery(fts_config, ${q.q}) query"

  private def mkSelectRank: Fragment =
    fr"ts_rank_cd(text_index, query, 4)"

  def replaceChunk(r: Chunk[FtsRecord]): ConnectionIO[Int] =
    r.traverse(replace).map(_.foldLeft(0)(_ + _))

  def replace(r: FtsRecord): ConnectionIO[Int] =
    (fr"INSERT INTO $table (id,item_id,collective,lang,attach_id,folder_id,attach_name,attach_content,item_name,item_notes,fts_config) VALUES (" ++
      commas(
        sql"${r.id}",
        sql"${r.itemId}",
        sql"${r.collective}",
        sql"${r.language}",
        sql"${r.attachId}",
        sql"${r.folderId}",
        sql"${r.attachName}",
        sql"${r.attachContent}",
        sql"${r.itemName}",
        sql"${r.itemNotes}",
        sql"${pgConfig(r.language)}::regconfig"
      ) ++ sql") on conflict (id) do update set " ++ commas(
        sql"lang = ${r.language}",
        sql"folder_id = ${r.folderId}",
        sql"attach_name = ${r.attachName}",
        sql"attach_content = ${r.attachContent}",
        sql"item_name = ${r.itemName}",
        sql"item_notes = ${r.itemNotes}",
        sql"fts_config = ${pgConfig(r.language)}::regconfig"
      )).update.run

  def update(r: FtsRecord): ConnectionIO[Int] =
    (fr"UPDATE $table SET" ++ commas(
      sql"lang = ${r.language}",
      sql"folder_id = ${r.folderId}",
      sql"attach_name = ${r.attachName}",
      sql"attach_content = ${r.attachContent}",
      sql"item_name = ${r.itemName}",
      sql"item_notes = ${r.itemNotes}",
      sql"fts_config = ${pgConfig(r.language)}::regconfig"
    ) ++ fr"WHERE id = ${r.id}").update.run

  def updateChunk(r: Chunk[FtsRecord]): ConnectionIO[Int] =
    r.traverse(update).map(_.foldLeft(0)(_ + _))

  def updateFolder(
      itemId: Ident,
      collective: Ident,
      folder: Option[Ident]
  ): ConnectionIO[Int] =
    (sql"UPDATE $table" ++
      fr"SET folder_id = $folder" ++
      fr"WHERE item_id = $itemId AND collective = $collective").update.run

  def deleteByItemId(itemId: Ident): ConnectionIO[Int] =
    sql"DELETE FROM $table WHERE item_id = $itemId".update.run

  def deleteByAttachId(attachId: Ident): ConnectionIO[Int] =
    sql"DELETE FROM $table WHERE attach_id = $attachId".update.run

  def deleteAll: ConnectionIO[Int] =
    sql"DELETE FROM $table".update.run

  def delete(collective: Ident): ConnectionIO[Int] =
    sql"DELETE FROM $table WHERE collective = $collective".update.run

  def resetAll: ConnectionIO[Int] = {
    val dropFlyway = sql"DROP TABLE IF EXISTS flyway_fts_history".update.run
    val dropSearch = sql"DROP TABLE IF EXISTS $table".update.run
    for {
      a <- dropFlyway
      b <- dropSearch
    } yield a + b
  }

  private def commas(fr: Fragment, frn: Fragment*): Fragment =
    frn.foldLeft(fr)(_ ++ fr"," ++ _)

  def pgConfig(language: Language): String =
    language match {
      case Language.English    => "english"
      case Language.German     => "german"
      case Language.French     => "french"
      case Language.Italian    => "italian"
      case Language.Spanish    => "spanish"
      case Language.Hungarian  => "hungarian"
      case Language.Portuguese => "portuguese"
      case Language.Czech      => "simple" // ?
      case Language.Danish     => "danish"
      case Language.Finnish    => "finnish"
      case Language.Norwegian  => "norwegian"
      case Language.Swedish    => "swedish"
      case Language.Russian    => "russian"
      case Language.Romanian   => "romanian"
      case Language.Dutch      => "dutch"
      case Language.Latvian    => "lithuanian" // ?
      case Language.Japanese   => "simple"
      case Language.Hebrew     => "simple"
    }
}
