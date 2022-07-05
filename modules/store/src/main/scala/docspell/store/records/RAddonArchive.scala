/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList

import docspell.addons.{AddonArchive, AddonMeta, AddonTriggerType}
import docspell.common._
import docspell.store.file.FileUrlReader
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

final case class RAddonArchive(
    id: Ident,
    cid: CollectiveId,
    fileId: FileKey,
    originalUrl: Option[LenientUri],
    name: String,
    version: String,
    description: Option[String],
    triggers: Set[AddonTriggerType],
    created: Timestamp
) {

  def nameAndVersion: String =
    s"$name-$version"

  def isUnchanged(meta: AddonMeta): Boolean =
    name == meta.meta.name &&
      version == meta.meta.version &&
      description == meta.meta.description

  def isChanged(meta: AddonMeta): Boolean =
    !isUnchanged(meta)

  def asArchive: AddonArchive =
    AddonArchive(FileUrlReader.url(fileId), name, version)

  def update(file: FileKey, meta: AddonMeta): RAddonArchive =
    copy(
      fileId = file,
      name = meta.meta.name,
      version = meta.meta.version,
      description = meta.meta.description,
      triggers = meta.triggers.getOrElse(Set.empty)
    )
}

object RAddonArchive {
  case class Table(alias: Option[String]) extends TableDef {
    val tableName = "addon_archive"

    val id = Column[Ident]("id", this)
    val cid = Column[CollectiveId]("coll_id", this)
    val fileId = Column[FileKey]("file_id", this)
    val originalUrl = Column[LenientUri]("original_url", this)
    val name = Column[String]("name", this)
    val version = Column[String]("version", this)
    val description = Column[String]("description", this)
    val triggers = Column[Set[AddonTriggerType]]("triggers", this)
    val created = Column[Timestamp]("created", this)

    val all: NonEmptyList[Column[_]] =
      NonEmptyList.of(
        id,
        cid,
        fileId,
        originalUrl,
        name,
        version,
        description,
        triggers,
        created
      )
  }

  def apply(
      id: Ident,
      cid: CollectiveId,
      fileId: FileKey,
      originalUrl: Option[LenientUri],
      meta: AddonMeta,
      created: Timestamp
  ): RAddonArchive =
    RAddonArchive(
      id,
      cid,
      fileId,
      originalUrl,
      meta.meta.name,
      meta.meta.version,
      meta.meta.description,
      meta.triggers.getOrElse(Set.empty),
      created
    )

  def as(alias: String): Table =
    Table(Some(alias))

  val T = Table(None)

  def insert(r: RAddonArchive, silent: Boolean): ConnectionIO[Int] = {
    val values =
      sql"${r.id}, ${r.cid}, ${r.fileId}, ${r.originalUrl}, ${r.name}, ${r.version}, ${r.description}, ${r.triggers}, ${r.created}"

    if (silent) DML.insertSilent(T, T.all, values)
    else DML.insert(T, T.all, values)
  }

  def existsByUrl(cid: CollectiveId, url: LenientUri): ConnectionIO[Boolean] =
    Select(
      select(count(T.id)),
      from(T),
      T.cid === cid && T.originalUrl === url
    ).build.query[Int].unique.map(_ > 0)

  def findByUrl(cid: CollectiveId, url: LenientUri): ConnectionIO[Option[RAddonArchive]] =
    Select(
      select(T.all),
      from(T),
      T.cid === cid && T.originalUrl === url
    ).build.query[RAddonArchive].option

  def findByNameAndVersion(
      cid: CollectiveId,
      name: String,
      version: String
  ): ConnectionIO[Option[RAddonArchive]] =
    Select(
      select(T.all),
      from(T),
      T.cid === cid && T.name === name && T.version === version
    ).build.query[RAddonArchive].option

  def findById(cid: CollectiveId, id: Ident): ConnectionIO[Option[RAddonArchive]] =
    Select(
      select(T.all),
      from(T),
      T.cid === cid && T.id === id
    ).build.query[RAddonArchive].option

  def findByIds(
      cid: CollectiveId,
      ids: NonEmptyList[Ident]
  ): ConnectionIO[List[RAddonArchive]] =
    Select(
      select(T.all),
      from(T),
      T.cid === cid && T.id.in(ids)
    ).orderBy(T.name).build.query[RAddonArchive].to[List]

  def update(r: RAddonArchive): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === r.id && T.cid === r.cid,
      DML.set(
        T.fileId.setTo(r.fileId),
        T.originalUrl.setTo(r.originalUrl),
        T.name.setTo(r.name),
        T.version.setTo(r.version),
        T.description.setTo(r.description),
        T.triggers.setTo(r.triggers)
      )
    )

  def listAll(cid: CollectiveId): ConnectionIO[List[RAddonArchive]] =
    Select(
      select(T.all),
      from(T),
      T.cid === cid
    ).orderBy(T.name.asc).build.query[RAddonArchive].to[List]

  def deleteById(cid: CollectiveId, id: Ident): ConnectionIO[Int] =
    DML.delete(T, T.cid === cid && T.id === id)

  implicit val jsonDecoder: Decoder[RAddonArchive] = deriveDecoder
  implicit val jsonEncoder: Encoder[RAddonArchive] = deriveEncoder
}
