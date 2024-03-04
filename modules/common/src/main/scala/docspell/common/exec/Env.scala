/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

case class Env(values: Map[String, String]) {

  def add(name: String, value: String): Env =
    copy(values.updated(name, value))

  def addAll(v: Map[String, String]): Env =
    Env(values ++ v)

  def addAll(e: Env): Env =
    Env(values ++ e.values)

  def modifyValue(f: String => String): Env =
    Env(values.view.mapValues(f).toMap)

  def ++(e: Env) = addAll(e)

  def foreach(f: (String, String) => Unit): Unit =
    values.foreach(t => f(t._1, t._2))

  def map[A](f: (String, String) => A): Seq[A] =
    values.map(f.tupled).toSeq

  def mapConcat[A](f: (String, String) => Seq[A]): Seq[A] =
    values.flatMap(f.tupled).toSeq
}

object Env {
  val empty: Env = Env(Map.empty)

  def of(nv: (String, String)*): Env =
    Env(Map(nv: _*))
}
