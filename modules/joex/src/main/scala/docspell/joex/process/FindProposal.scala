/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import java.time.ZoneId

import cats.effect.Sync
import cats.implicits._
import cats.{Applicative, FlatMap}

import docspell.analysis.contact._
import docspell.common.MetaProposal.Candidate
import docspell.common._
import docspell.joex.Config
import docspell.scheduler.{Context, Task}
import docspell.store.Store
import docspell.store.records._

/** Super simple approach to find corresponding meta data to an item by looking up values
  * from NER in the users address book.
  */
object FindProposal {
  type Args = ProcessItemArgs

  def apply[F[_]: Sync](
      cfg: Config.TextAnalysis,
      store: Store[F]
  )(data: ItemData): Task[F, Args, ItemData] =
    Task { ctx =>
      val rmas = data.metas.map(rm => rm.copy(nerlabels = removeDuplicates(rm.nerlabels)))
      for {
        _ <- ctx.logger.info("Starting find-proposal")
        rmv <- rmas
          .traverse(rm =>
            processAttachment(cfg, rm, data.findDates(rm), ctx, store)
              .map(ml => rm.copy(proposals = ml))
          )
        clp <- lookupClassifierProposals(ctx, store, data.classifyProposals)
      } yield data.copy(metas = rmv, classifyProposals = clp)
    }

  def lookupClassifierProposals[F[_]: Sync](
      ctx: Context[F, Args],
      store: Store[F],
      mpList: MetaProposalList
  ): F[MetaProposalList] = {
    val coll = ctx.args.meta.collective

    def lookup(mp: MetaProposal): F[Option[IdRef]] =
      mp.proposalType match {
        case MetaProposalType.CorrOrg =>
          store
            .transact(
              ROrganization
                .findLike(coll, mp.values.head.ref.name.toLowerCase, OrgUse.notDisabled)
                .map(_.headOption)
            )
            .flatTap(oref =>
              ctx.logger.debug(s"Found classifier organization for $mp: $oref")
            )
        case MetaProposalType.CorrPerson =>
          store
            .transact(
              RPerson
                .findLike(
                  coll,
                  mp.values.head.ref.name.toLowerCase,
                  PersonUse.correspondentAndBoth
                )
                .map(_.headOption)
            )
            .flatTap(oref =>
              ctx.logger.debug(s"Found classifier corr-person for $mp: $oref")
            )
        case MetaProposalType.ConcPerson =>
          store
            .transact(
              RPerson
                .findLike(
                  coll,
                  mp.values.head.ref.name.toLowerCase,
                  PersonUse.concerningAndBoth
                )
                .map(_.headOption)
            )
            .flatTap(oref =>
              ctx.logger.debug(s"Found classifier conc-person for $mp: $oref")
            )
        case MetaProposalType.ConcEquip =>
          store
            .transact(
              REquipment
                .findLike(
                  coll,
                  mp.values.head.ref.name.toLowerCase,
                  EquipmentUse.notDisabled
                )
                .map(_.headOption)
            )
            .flatTap(oref =>
              ctx.logger.debug(s"Found classifier conc-equip for $mp: $oref")
            )
        case MetaProposalType.DocDate =>
          (None: Option[IdRef]).pure[F]

        case MetaProposalType.DueDate =>
          (None: Option[IdRef]).pure[F]
      }

    def updateRef(mp: MetaProposal)(idRef: Option[IdRef]): Option[MetaProposal] =
      idRef // this proposal contains a single value only, since coming from classifier
        .map(ref => mp.copy(values = mp.values.map(_.copy(ref = ref))))

    ctx.logger.debug(s"Looking up classifier results: ${mpList.proposals}") *>
      mpList.proposals
        .traverse(mp => lookup(mp).map(updateRef(mp)))
        .map(_.flatten)
        .map(MetaProposalList.apply)
  }

  def processAttachment[F[_]: Sync](
      cfg: Config.TextAnalysis,
      rm: RAttachmentMeta,
      rd: Vector[NerDateLabel],
      ctx: Context[F, Args],
      store: Store[F]
  ): F[MetaProposalList] = {
    val finder = Finder.searchExact(ctx, store).next(Finder.searchFuzzy(ctx, store))
    List(finder.find(rm.nerlabels), makeDateProposal(cfg, rd))
      .traverse(identity)
      .map(MetaProposalList.flatten)
  }

  def makeDateProposal[F[_]: Sync](
      cfg: Config.TextAnalysis,
      dates: Vector[NerDateLabel]
  ): F[MetaProposalList] =
    Timestamp.current[F].map { now =>
      val maxFuture = now.plus(Duration.years(cfg.nlp.maxDueDateYears.toLong))
      val latestFirst = dates
        .filter(_.date.isBefore(maxFuture.toUtcDate))
        .sortWith((l1, l2) => l1.date.isAfter(l2.date))
      val nowDate = now.value.atZone(ZoneId.of("GMT")).toLocalDate
      val (after, before) = latestFirst.span(ndl => ndl.date.isAfter(nowDate))

      val dueDates = MetaProposalList.fromSeq1(
        MetaProposalType.DueDate,
        after.map(ndl =>
          Candidate(
            IdRef(Ident.unsafe(ndl.date.toString), ndl.date.toString),
            Set(ndl.label)
          )
        )
      )
      val itemDates = MetaProposalList.fromSeq1(
        MetaProposalType.DocDate,
        before.map(ndl =>
          Candidate(
            IdRef(Ident.unsafe(ndl.date.toString), ndl.date.toString),
            Set(ndl.label)
          )
        )
      )

      MetaProposalList.flatten(Seq(dueDates, itemDates))
    }

  def removeDuplicates(labels: List[NerLabel]): List[NerLabel] =
    labels
      .sortBy(_.startPosition)
      .foldLeft((Set.empty[String], List.empty[NerLabel])) { case ((seen, result), el) =>
        if (seen.contains(el.tag.name + el.label.toLowerCase)) (seen, result)
        else (seen + (el.tag.name + el.label.toLowerCase), el :: result)
      }
      ._2

  trait Finder[F[_]] { self =>
    def find(labels: Seq[NerLabel]): F[MetaProposalList]

    def contraMap(f: Seq[NerLabel] => Seq[NerLabel]): Finder[F] =
      labels => self.find(f(labels))

    def filterLabels(f: NerLabel => Boolean): Finder[F] =
      contraMap(_.filter(f))

    def flatMap(f: MetaProposalList => Finder[F])(implicit F: FlatMap[F]): Finder[F] =
      labels => self.find(labels).flatMap(ml => f(ml).find(labels))

    def map(
        f: MetaProposalList => MetaProposalList
    )(implicit F: Applicative[F]): Finder[F] =
      labels => self.find(labels).map(f)

    def next(f: Finder[F])(implicit F: FlatMap[F], F3: Applicative[F]): Finder[F] =
      flatMap { ml0 =>
        if (ml0.hasResultsAll) Finder.unit[F](ml0)
        else f.map(ml1 => ml0.fillEmptyFrom(ml1))
      }

    def nextWhenEmpty(f: Finder[F], mt0: MetaProposalType, mts: MetaProposalType*)(
        implicit
        F: FlatMap[F],
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

    def searchExact[F[_]: Sync](ctx: Context[F, Args], store: Store[F]): Finder[F] =
      labels =>
        labels.toList
          .traverse(nl => search(nl, exact = true, ctx, store))
          .map(MetaProposalList.flatten)

    def searchFuzzy[F[_]: Sync](ctx: Context[F, Args], store: Store[F]): Finder[F] =
      labels =>
        labels.toList
          .traverse(nl => search(nl, exact = false, ctx, store))
          .map(MetaProposalList.flatten)
  }

  private def search[F[_]: Sync](
      nt: NerLabel,
      exact: Boolean,
      ctx: Context[F, ProcessItemArgs],
      store: Store[F]
  ): F[MetaProposalList] = {
    val value =
      if (exact) normalizeSearchValue(nt.label)
      else s"%${normalizeSearchValue(nt.label)}%"
    val minLength =
      if (exact) 2 else 5

    if (value.length < minLength)
      ctx.logger
        .debug(s"Skipping too small value '$value' (original '${nt.label}').")
        .map(_ => MetaProposalList.empty)
    else
      nt.tag match {
        case NerTag.Organization =>
          ctx.logger.debug(s"Looking for organizations: $value") *>
            store
              .transact(
                ROrganization
                  .findLike(ctx.args.meta.collective, value, OrgUse.notDisabled)
              )
              .map(MetaProposalList.from(MetaProposalType.CorrOrg, nt))

        case NerTag.Person =>
          val s1 = store
            .transact(
              RPerson
                .findLike(ctx.args.meta.collective, value, PersonUse.concerningAndBoth)
            )
            .map(MetaProposalList.from(MetaProposalType.ConcPerson, nt))
          val s2 = store
            .transact(
              RPerson
                .findLike(ctx.args.meta.collective, value, PersonUse.correspondentAndBoth)
            )
            .map(MetaProposalList.from(MetaProposalType.CorrPerson, nt))
          val s3 =
            store
              .transact(
                ROrganization
                  .findLike(ctx.args.meta.collective, value, OrgUse.notDisabled)
              )
              .map(MetaProposalList.from(MetaProposalType.CorrOrg, nt))
          ctx.logger.debug(s"Looking for persons and organizations: $value") *> (for {
            ml0 <- s1
            ml1 <- s2
            ml2 <- s3
          } yield ml0 |+| ml1 |+| ml2)

        case NerTag.Location =>
          ctx.logger
            .debug(s"NerTag 'Location' is currently not used. Ignoring value '$value'.")
            .map(_ => MetaProposalList.empty)

        case NerTag.Misc =>
          ctx.logger.debug(s"Looking for equipments: $value") *>
            store
              .transact(
                REquipment
                  .findLike(ctx.args.meta.collective, value, EquipmentUse.notDisabled)
              )
              .map(MetaProposalList.from(MetaProposalType.ConcEquip, nt))

        case NerTag.Email =>
          searchContact(nt, ContactKind.Email, value, ctx, store)

        case NerTag.Website =>
          if (!exact) {
            val searchString = Domain
              .domainFromUri(nt.label.toLowerCase)
              .toOption
              .map(_.toPrimaryDomain.asString)
              .map(s => s"%$s%")
              .getOrElse(value)
            searchContact(nt, ContactKind.Website, searchString, ctx, store)
          } else
            searchContact(nt, ContactKind.Website, value, ctx, store)

        case NerTag.Date =>
          // There is no database search required for this tag
          MetaProposalList.empty.pure[F]
      }
  }

  private def searchContact[F[_]: Sync](
      nt: NerLabel,
      kind: ContactKind,
      value: String,
      ctx: Context[F, ProcessItemArgs],
      store: Store[F]
  ): F[MetaProposalList] = {
    val orgs = store
      .transact(ROrganization.findLike(ctx.args.meta.collective, kind, value))
      .map(MetaProposalList.from(MetaProposalType.CorrOrg, nt))
    val corrP = store
      .transact(
        RPerson
          .findLike(ctx.args.meta.collective, kind, value, PersonUse.correspondentAndBoth)
      )
      .map(MetaProposalList.from(MetaProposalType.CorrPerson, nt))
    val concP = store
      .transact(
        RPerson
          .findLike(ctx.args.meta.collective, kind, value, PersonUse.concerningAndBoth)
      )
      .map(MetaProposalList.from(MetaProposalType.CorrPerson, nt))

    ctx.logger.debug(s"Looking with $kind: $value") *>
      List(orgs, corrP, concP).traverse(identity).map(MetaProposalList.flatten)
  }

  // The backslash *must* be stripped from search strings.
  private[this] val invalidSearch =
    "…[]^<>=ſ{}|`\"';\\".toSet

  private def normalizeSearchValue(str: String): String =
    str.toLowerCase.filter(c => !invalidSearch.contains(c))
}
