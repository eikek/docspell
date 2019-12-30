package docspell.joex.process

import java.time.ZoneId

import cats.{Applicative, FlatMap}
import cats.implicits._
import cats.effect.Sync
import docspell.common.MetaProposal.Candidate
import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.records.{RAttachmentMeta, REquipment, ROrganization, RPerson}
import docspell.text.contact.Domain

/** Super simple approach to find corresponding meta data to an item
  * by looking up values from NER in the users address book.
  *
  */
object FindProposal {

  def apply[F[_]: Sync](data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      val rmas = data.metas.map(rm => rm.copy(nerlabels = removeDuplicates(rm.nerlabels)))

      ctx.logger.info("Starting find-proposal") *>
        rmas
          .traverse(rm =>
            processAttachment(rm, data.findDates(rm), ctx).map(ml => rm.copy(proposals = ml))
          )
          .flatMap(rmv =>
            rmv
              .traverse(rm =>
                ctx.logger.debug(s"Storing attachment proposals: ${rm.proposals}") *>
                  ctx.store.transact(RAttachmentMeta.updateProposals(rm.id, rm.proposals))
              )
              .map(_ => data.copy(metas = rmv))
          )
    }

  def processAttachment[F[_]: Sync](
      rm: RAttachmentMeta,
      rd: Vector[NerDateLabel],
      ctx: Context[F, ProcessItemArgs]
  ): F[MetaProposalList] = {
    val finder = Finder.searchExact(ctx).next(Finder.searchFuzzy(ctx))
    List(finder.find(rm.nerlabels), makeDateProposal(rd))
      .traverse(identity)
      .map(MetaProposalList.flatten)
  }

  def makeDateProposal[F[_]: Sync](dates: Vector[NerDateLabel]): F[MetaProposalList] =
    Timestamp.current[F].map { now =>
      val latestFirst     = dates.sortWith((l1, l2) => l1.date.isAfter(l2.date))
      val nowDate         = now.value.atZone(ZoneId.of("GMT")).toLocalDate
      val (after, before) = latestFirst.span(ndl => ndl.date.isAfter(nowDate))

      val dueDates = MetaProposalList.fromSeq1(
        MetaProposalType.DueDate,
        after.map(ndl =>
          Candidate(IdRef(Ident.unsafe(ndl.date.toString), ndl.date.toString), Set(ndl.label))
        )
      )
      val itemDates = MetaProposalList.fromSeq1(
        MetaProposalType.DocDate,
        before.map(ndl =>
          Candidate(IdRef(Ident.unsafe(ndl.date.toString), ndl.date.toString), Set(ndl.label))
        )
      )

      MetaProposalList.flatten(Seq(dueDates, itemDates))
    }

  def removeDuplicates(labels: List[NerLabel]): List[NerLabel] =
    labels
      .foldLeft((Set.empty[String], List.empty[NerLabel])) {
        case ((seen, result), el) =>
          if (seen.contains(el.tag.name + el.label.toLowerCase)) (seen, result)
          else (seen + (el.tag.name + el.label.toLowerCase), el :: result)
      }
      ._2
      .sortBy(_.startPosition)

  trait Finder[F[_]] { self =>
    def find(labels: Seq[NerLabel]): F[MetaProposalList]

    def contraMap(f: Seq[NerLabel] => Seq[NerLabel]): Finder[F] =
      labels => self.find(f(labels))

    def filterLabels(f: NerLabel => Boolean): Finder[F] =
      contraMap(_.filter(f))

    def flatMap(f: MetaProposalList => Finder[F])(implicit F: FlatMap[F]): Finder[F] =
      labels => self.find(labels).flatMap(ml => f(ml).find(labels))

    def map(f: MetaProposalList => MetaProposalList)(implicit F: Applicative[F]): Finder[F] =
      labels => self.find(labels).map(f)

    def next(f: Finder[F])(implicit F: FlatMap[F], F3: Applicative[F]): Finder[F] =
      flatMap({ ml0 =>
        if (ml0.hasResultsAll) Finder.unit[F](ml0)
        else f.map(ml1 => ml0.fillEmptyFrom(ml1))
      })

    def nextWhenEmpty(f: Finder[F], mt0: MetaProposalType, mts: MetaProposalType*)(
        implicit F: FlatMap[F],
        F2: Applicative[F]
    ): Finder[F] =
      flatMap { res0 =>
        if (res0.hasResults(mt0, mts: _*)) Finder.unit[F](res0)
        else f.map(res1 => res0.fillEmptyFrom(res1))
      }
  }

  object Finder {
    def none[F[_]: Applicative]: Finder[F] =
      _ => MetaProposalList.empty.pure[F]

    def unit[F[_]: Applicative](value: MetaProposalList): Finder[F] =
      _ => value.pure[F]

    def searchExact[F[_]: Sync](ctx: Context[F, ProcessItemArgs]): Finder[F] =
      labels => labels.toList.traverse(nl => search(nl, true, ctx)).map(MetaProposalList.flatten)

    def searchFuzzy[F[_]: Sync](ctx: Context[F, ProcessItemArgs]): Finder[F] =
      labels => labels.toList.traverse(nl => search(nl, false, ctx)).map(MetaProposalList.flatten)
  }

  private def search[F[_]: Sync](
      nt: NerLabel,
      exact: Boolean,
      ctx: Context[F, ProcessItemArgs]
  ): F[MetaProposalList] = {
    val value =
      if (exact) normalizeSearchValue(nt.label)
      else s"%${normalizeSearchValue(nt.label)}%"
    val minLength =
      if (exact) 2 else 5

    if (value.length < minLength) {
      ctx.logger
        .debug(s"Skipping too small value '$value' (original '${nt.label}').")
        .map(_ => MetaProposalList.empty)
    } else
      nt.tag match {
        case NerTag.Organization =>
          ctx.logger.debug(s"Looking for organizations: $value") *>
            ctx.store
              .transact(ROrganization.findLike(ctx.args.meta.collective, value))
              .map(MetaProposalList.from(MetaProposalType.CorrOrg, nt))

        case NerTag.Person =>
          val s1 = ctx.store
            .transact(RPerson.findLike(ctx.args.meta.collective, value, true))
            .map(MetaProposalList.from(MetaProposalType.ConcPerson, nt))
          val s2 = ctx.store
            .transact(RPerson.findLike(ctx.args.meta.collective, value, false))
            .map(MetaProposalList.from(MetaProposalType.CorrPerson, nt))
          ctx.logger.debug(s"Looking for persons: $value") *> (for {
            ml0 <- s1
            ml1 <- s2
          } yield ml0 |+| ml1)

        case NerTag.Location =>
          ctx.logger
            .debug(s"NerTag 'Location' is currently not used. Ignoring value '$value'.")
            .map(_ => MetaProposalList.empty)

        case NerTag.Misc =>
          ctx.logger.debug(s"Looking for equipments: $value") *>
            ctx.store
              .transact(REquipment.findLike(ctx.args.meta.collective, value))
              .map(MetaProposalList.from(MetaProposalType.ConcEquip, nt))

        case NerTag.Email =>
          searchContact(nt, ContactKind.Email, value, ctx)

        case NerTag.Website =>
          if (!exact) {
            val searchString = Domain
              .domainFromUri(nt.label.toLowerCase)
              .toOption
              .map(_.toPrimaryDomain.asString)
              .map(s => s"%$s%")
              .getOrElse(value)
            searchContact(nt, ContactKind.Website, searchString, ctx)
          } else {
            searchContact(nt, ContactKind.Website, value, ctx)
          }

        case NerTag.Date =>
          // There is no database search required for this tag
          MetaProposalList.empty.pure[F]
      }
  }

  private def searchContact[F[_]: Sync](
      nt: NerLabel,
      kind: ContactKind,
      value: String,
      ctx: Context[F, ProcessItemArgs]
  ): F[MetaProposalList] = {
    val orgs = ctx.store
      .transact(ROrganization.findLike(ctx.args.meta.collective, kind, value))
      .map(MetaProposalList.from(MetaProposalType.CorrOrg, nt))
    val corrP = ctx.store
      .transact(RPerson.findLike(ctx.args.meta.collective, kind, value, false))
      .map(MetaProposalList.from(MetaProposalType.CorrPerson, nt))
    val concP = ctx.store
      .transact(RPerson.findLike(ctx.args.meta.collective, kind, value, true))
      .map(MetaProposalList.from(MetaProposalType.CorrPerson, nt))

    ctx.logger.debug(s"Looking with $kind: $value") *>
      List(orgs, corrP, concP).traverse(identity).map(MetaProposalList.flatten)
  }

  // The backslash *must* be stripped from search strings.
  private[this] val invalidSearch =
    "…_[]^<>=&ſ/{}*?@#$|~`+%\"';\\".toSet

  private def normalizeSearchValue(str: String): String =
    str.toLowerCase.filter(c => !invalidSearch.contains(c))
}
