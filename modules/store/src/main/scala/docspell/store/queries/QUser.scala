/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.implicits._

import docspell.common._
import docspell.store.qb.DML
import docspell.store.qb.DSL._
import docspell.store.records._

import doobie._

object QUser {
  private[this] val logger = docspell.logging.getLogger[ConnectionIO]

  final case class UserData(
      ownedFolders: List[Ident],
      sentMails: Int,
      shares: Int
  )

  def getUserData(cid: CollectiveId, uid: Ident): ConnectionIO[UserData] = {
    val folder = RFolder.as("f")
    val mail = RSentMail.as("m")
    val mitem = RSentMailItem.as("mi")
    val share = RShare.as("s")

    for {
      folders <- run(
        select(folder.name),
        from(folder),
        folder.owner === uid && folder.collective === cid
      ).query[Ident].to[List]
      mails <- run(
        select(count(mail.id)),
        from(mail)
          .innerJoin(mitem, mail.id === mitem.sentMailId),
        mail.uid === uid
      ).query[Int].unique
      shares <- run(
        select(count(share.id)),
        from(share),
        share.userId === uid
      ).query[Int].unique
    } yield UserData(folders, mails, shares)
  }

  def deleteUserAndData(uid: Ident): ConnectionIO[Int] =
    for {
      _ <- logger.info(s"Remove user ${uid.id}")

      n1 <- deleteUserFolders(uid)

      n2 <- deleteUserSentMails(uid)
      _ <- logger.info(s"Removed $n2 sent mails")

      n3 <- deleteRememberMe(uid)
      _ <- logger.info(s"Removed $n3 remember me tokens")

      n4 <- deleteTotp(uid)
      _ <- logger.info(s"Removed $n4 totp secrets")

      n5 <- deleteMailSettings(uid)
      _ <- logger.info(s"Removed $n5 mail settings")

      nu <- RUser.deleteById(uid)
    } yield nu + n1 + n2 + n3 + n4 + n5

  def deleteUserFolders(uid: Ident): ConnectionIO[Int] = {
    val folder = RFolder.as("f")
    val member = RFolderMember.as("fm")
    for {
      folders <- run(
        select(folder.id),
        from(folder),
        folder.owner === uid
      ).query[Ident].to[List]
      _ <- logger.info(s"Removing folders: ${folders.map(_.id)}")

      ri <- folders.traverse(RItem.removeFolder)
      _ <- logger.info(s"Removed folders from items: $ri")
      rs <- folders.traverse(RSource.removeFolder)
      _ <- logger.info(s"Removed folders from sources: $rs")
      rf <- folders.traverse(RFolderMember.deleteAll)
      _ <- logger.info(s"Removed folders from members: $rf")

      n1 <- DML.delete(member, member.user === uid)
      _ <- logger.info(s"Removed $n1 members for owning folders.")
      n2 <- DML.delete(folder, folder.owner === uid)
      _ <- logger.info(s"Removed $n2 folders.")

    } yield n1 + n2 + ri.sum + rs.sum + rf.sum
  }

  def deleteUserSentMails(uid: Ident): ConnectionIO[Int] = {
    val mail = RSentMail.as("m")
    for {
      ids <- run(select(mail.id), from(mail), mail.uid === uid).query[Ident].to[List]
      n1 <- ids.traverse(RSentMailItem.deleteMail)
      n2 <- ids.traverse(RSentMail.delete)
    } yield n1.sum + n2.sum
  }

  def deleteRememberMe(userId: Ident): ConnectionIO[Int] =
    DML.delete(RRememberMe.T, RRememberMe.T.userId === userId)

  def deleteTotp(uid: Ident): ConnectionIO[Int] =
    DML.delete(RTotp.T, RTotp.T.userId === uid)

  def deleteMailSettings(uid: Ident): ConnectionIO[Int] = {
    val smtp = RUserEmail.as("ms")
    val imap = RUserImap.as("mi")
    for {
      n1 <- DML.delete(smtp, smtp.uid === uid)
      n2 <- DML.delete(imap, imap.uid === uid)
    } yield n1 + n2
  }
}
