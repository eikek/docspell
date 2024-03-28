/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import cats.data.NonEmptyList
import fs2.Chunk

import docspell.common._
import docspell.ftsclient.FtsQuery

import doobie._
import doobie.implicits._

object FtsRepository extends DoobieMeta {
  private[this] val logger = docspell.logging.getLogger[ConnectionIO]
  val table = fr"ftspsql_search"

  def containsData: ConnectionIO[Boolean] =
    fr"select id from $table limit 1".query[String].option.map(_.isDefined)

  def containsNoData: ConnectionIO[Boolean] =
    containsData.map(!_)

  def searchSummary(pq: PgQueryParser, rn: RankNormalization)(
      q: FtsQuery
  ): ConnectionIO[SearchSummary] = {
    val selectRank = mkSelectRank(rn)
    val query = mkQueryPart(pq, q)

    fr"""select count(id), coalesce(max($selectRank), 0)
        |from $table, $query
        |where ${mkCondition(q)} AND query @@ text_index 
        |""".stripMargin
      .query[SearchSummary]
      .unique
  }

  def search(pq: PgQueryParser, rn: RankNormalization)(
      q: FtsQuery,
      withHighlighting: Boolean
  ): ConnectionIO[Vector[SearchResult]] = {
    val selectRank = mkSelectRank(rn)

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

    val query = mkQueryPart(pq, q)

    val sqlFrag =
      fr"""select $select 
          |from $table, $query
          |where ${mkCondition(q)} AND query @@ text_index 
          |order by rank desc
          |limit ${q.limit}
          |offset ${q.offset}
          |""".stripMargin

    logger.asUnsafe.trace(s"PSQL Fulltext query: $sqlFrag")
    sqlFrag.query[SearchResult].to[Vector]
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
        fr"(folder_id in ($ids) or folder_id is null)"
      }

    List(items, folders).flatten.foldLeft(coll)(_ ++ fr"AND" ++ _)
  }

  private def mkQueryPart(p: PgQueryParser, q: FtsQuery): Fragment = {
    val fname = Fragment.const(p.name)
    fr"$fname(fts_config, ${q.q}) query"
  }

  private def mkSelectRank(rn: RankNormalization): Fragment = {
    val bits = rn.value.toNonEmptyList.map(n => fr"$n").reduceLeft(_ ++ sql"|" ++ _)
    fr"ts_rank_cd(text_index, query, $bits)"
  }

  def replaceChunk(pgConfig: Language => String)(r: Chunk[FtsRecord]): ConnectionIO[Int] =
    r.traverse(replace(pgConfig)).map(_.foldLeft(0)(_ + _))

  def replace(
      pgConfig: Language => String
  )(r: FtsRecord): ConnectionIO[Int] =
    (fr"INSERT INTO $table (id,item_id,collective,lang,attach_id,folder_id,attach_name,attach_content,item_name,item_notes,fts_config) VALUES (" ++
      commas(
        fr"${r.id}",
        fr"${r.itemId}",
        fr"${r.collective}",
        fr"${r.language}",
        fr"${r.attachId}",
        fr"${r.folderId}",
        fr"${r.attachName}",
        fr"${r.attachContent}",
        fr"${r.itemName}",
        fr"${r.itemNotes}",
        fr"${pgConfig(r.language)}::regconfig"
      ) ++ fr") on conflict (id) do update set " ++ commas(
        fr"lang = ${r.language}",
        fr"folder_id = ${r.folderId}",
        fr"attach_name = ${r.attachName}",
        fr"attach_content = ${r.attachContent}",
        fr"item_name = ${r.itemName}",
        fr"item_notes = ${r.itemNotes}",
        fr"fts_config = ${pgConfig(r.language)}::regconfig"
      )).update.run

  def update(pgConfig: Language => String)(r: FtsRecord): ConnectionIO[Int] =
    (fr"UPDATE $table SET" ++ commas(
      fr"lang = ${r.language}",
      fr"folder_id = ${r.folderId}",
      fr"attach_name = ${r.attachName}",
      fr"attach_content = ${r.attachContent}",
      fr"item_name = ${r.itemName}",
      fr"item_notes = ${r.itemNotes}",
      fr"fts_config = ${pgConfig(r.language)}::regconfig"
    ) ++ fr"WHERE id = ${r.id}").update.run

  def updateChunk(pgConfig: Language => String)(r: Chunk[FtsRecord]): ConnectionIO[Int] =
    r.traverse(update(pgConfig)).map(_.foldLeft(0)(_ + _))

  def updateFolder(
      itemId: Ident,
      collective: CollectiveId,
      folder: Option[Ident]
  ): ConnectionIO[Int] =
    (fr"UPDATE $table" ++
      fr"SET folder_id = $folder" ++
      fr"WHERE item_id = $itemId AND collective = $collective").update.run

  def deleteByItemId(itemId: Ident): ConnectionIO[Int] =
    fr"DELETE FROM $table WHERE item_id = $itemId".update.run

  def deleteByAttachId(attachId: Ident): ConnectionIO[Int] =
    fr"DELETE FROM $table WHERE attach_id = $attachId".update.run

  def deleteAll: ConnectionIO[Int] =
    fr"DELETE FROM $table".update.run

  def delete(collective: CollectiveId): ConnectionIO[Int] =
    fr"DELETE FROM $table WHERE collective = $collective".update.run

  def resetAll: ConnectionIO[Int] = {
    val dropFlyway = fr"DROP TABLE IF EXISTS flyway_fts_history".update.run
    val dropSearch = fr"DROP TABLE IF EXISTS $table".update.run
    for {
      a <- dropFlyway
      b <- dropSearch
    } yield a + b
  }

  private def commas(fr: Fragment, frn: Fragment*): Fragment =
    frn.foldLeft(fr)(_ ++ fr"," ++ _)

  def getPgConfig(select: PartialFunction[Language, String])(language: Language): String =
    select.applyOrElse(language, defaultPgConfig)

  def defaultPgConfig(language: Language): String =
    language match {
      case Language.English    => "english"
      case Language.German     => "german"
      case Language.French     => "french"
      case Language.Italian    => "italian"
      case Language.Spanish    => "spanish"
      case Language.Hungarian  => "hungarian"
      case Language.Portuguese => "portuguese"
      case Language.Danish     => "danish"
      case Language.Finnish    => "finnish"
      case Language.Norwegian  => "norwegian"
      case Language.Swedish    => "swedish"
      case Language.Russian    => "russian"
      case Language.Romanian   => "romanian"
      case Language.Dutch      => "dutch"
      case Language.Czech      => "simple"
      case Language.Latvian    => "simple"
      case Language.Japanese   => "simple"
      case Language.JpnVert    => "simple"
      case Language.Hebrew     => "simple"
      case Language.Lithuanian => "simple"
      case Language.Polish     => "simple"
      case Language.Estonian   => "simple"
      case Language.Ukrainian  => "simple"
      case Language.Khmer      => "simple"
      case Language.Slovak     => "simple"
    }
}
