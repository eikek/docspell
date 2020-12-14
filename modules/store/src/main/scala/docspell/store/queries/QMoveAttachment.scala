package docspell.store.queries

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.records._

import doobie.implicits._
import doobie.{Query => _, _}

object QMoveAttachment {
  def moveAttachmentBefore(
      itemId: Ident,
      source: Ident,
      target: Ident
  ): ConnectionIO[Int] = {

    // rs < rt
    def moveBack(rs: RAttachment, rt: RAttachment): ConnectionIO[Int] =
      for {
        n <- RAttachment.decPositions(itemId, rs.position, rt.position)
        k <- RAttachment.updatePosition(rs.id, rt.position)
      } yield n + k

    // rs > rt
    def moveForward(rs: RAttachment, rt: RAttachment): ConnectionIO[Int] =
      for {
        n <- RAttachment.incPositions(itemId, rt.position, rs.position)
        k <- RAttachment.updatePosition(rs.id, rt.position)
      } yield n + k

    (for {
      _ <- OptionT.liftF(
        if (source == target)
          Sync[ConnectionIO].raiseError(new Exception("Attachments are the same!"))
        else ().pure[ConnectionIO]
      )
      rs <- OptionT(RAttachment.findById(source)).filter(_.itemId == itemId)
      rt <- OptionT(RAttachment.findById(target)).filter(_.itemId == itemId)
      n <- OptionT.liftF(
        if (rs.position == rt.position || rs.position + 1 == rt.position)
          0.pure[ConnectionIO]
        else if (rs.position < rt.position) moveBack(rs, rt)
        else moveForward(rs, rt)
      )
    } yield n).getOrElse(0)

  }
}
