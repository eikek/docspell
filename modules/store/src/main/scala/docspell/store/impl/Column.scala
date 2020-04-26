package docspell.store.impl

import doobie._, doobie.implicits._
import docspell.store.impl.DoobieSyntax._

case class Column(name: String, ns: String = "", alias: String = "") {

  val f = {
    val col =
      if (ns.isEmpty) Fragment.const(name)
      else Fragment.const(ns + "." + name)
    if (alias.isEmpty) col
    else col ++ fr"as" ++ Fragment.const(alias)
  }

  def lowerLike[A: Put](value: A): Fragment =
    fr"lower(" ++ f ++ fr") LIKE $value"

  def like[A: Put](value: A): Fragment =
    f ++ fr"LIKE $value"

  def is[A: Put](value: A): Fragment =
    f ++ fr" = $value"

  def is[A: Put](ov: Option[A]): Fragment = ov match {
    case Some(v) => f ++ fr" = $v"
    case None    => fr"is null"
  }

  def is(c: Column): Fragment =
    f ++ fr"=" ++ c.f

  def isSubquery(sq: Fragment): Fragment =
    f ++ fr"=" ++ fr"(" ++ sq ++ fr")"

  def isNot[A: Put](value: A): Fragment =
    f ++ fr"<> $value"

  def isNull: Fragment =
    f ++ fr"is null"

  def isNotNull: Fragment =
    f ++ fr"is not null"

  def isIn(values: Seq[Fragment]): Fragment =
    f ++ fr"IN (" ++ commas(values) ++ fr")"

  def isIn(frag: Fragment): Fragment =
    f ++ fr"IN (" ++ frag ++ fr")"

  def isOrDiscard[A: Put](value: Option[A]): Fragment =
    value match {
      case Some(v) => is(v)
      case None    => Fragment.empty
    }

  def isOneOf[A: Put](values: Seq[A]): Fragment = {
    val vals = values.map(v => sql"$v")
    isIn(vals)
  }

  def isNotOneOf[A: Put](values: Seq[A]): Fragment = {
    val vals = values.map(v => sql"$v")
    sql"(" ++ f ++ fr"is null or" ++ f ++ fr"not IN (" ++ commas(vals) ++ sql"))"
  }

  def isGt[A: Put](a: A): Fragment =
    f ++ fr"> $a"

  def isGt(c: Column): Fragment =
    f ++ fr">" ++ c.f

  def isLt[A: Put](a: A): Fragment =
    f ++ fr"< $a"

  def isLt(c: Column): Fragment =
    f ++ fr"<" ++ c.f

  def setTo[A: Put](value: A): Fragment =
    is(value)

  def setTo[A: Put](va: Option[A]): Fragment =
    f ++ fr" = $va"

  def ++(next: Fragment): Fragment =
    f.++(next)

  def prefix(ns: String): Column =
    Column(name, ns)

  def as(alias: String): Column =
    Column(name, ns, alias)

  def desc: Fragment =
    f ++ fr"desc"
  def asc: Fragment =
    f ++ fr"asc"

}
