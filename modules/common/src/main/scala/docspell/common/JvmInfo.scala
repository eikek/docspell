/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.time.Instant

import scala.jdk.CollectionConverters._

import cats.effect._
import cats.implicits._

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

case class JvmInfo(
    id: Ident,
    pidHost: String,
    ncpu: Int,
    inputArgs: List[String],
    libraryPath: String,
    specVendor: String,
    specVersion: String,
    startTime: Timestamp,
    uptime: Duration,
    vmName: String,
    vmVendor: String,
    vmVersion: String,
    heapUsage: JvmInfo.MemoryUsage,
    props: Map[String, String]
)

object JvmInfo {

  def create[F[_]: Sync](id: Ident): F[JvmInfo] =
    MemoryUsage.createHeap[F].flatMap { mu =>
      Sync[F].delay {
        val rmb = management.ManagementFactory.getRuntimeMXBean()
        val rt  = Runtime.getRuntime()
        JvmInfo(
          id,
          pidHost = rmb.getName(),
          ncpu = rt.availableProcessors(),
          inputArgs = rmb.getInputArguments().asScala.toList,
          libraryPath = rmb.getLibraryPath(),
          specVendor = rmb.getSpecVendor(),
          specVersion = rmb.getSpecVersion(),
          startTime = Timestamp(Instant.ofEpochMilli(rmb.getStartTime())),
          uptime = Duration.millis(rmb.getUptime()),
          vmName = rmb.getVmName(),
          vmVendor = rmb.getVmVendor(),
          vmVersion = rmb.getVmVersion(),
          heapUsage = mu,
          props = rmb.getSystemProperties().asScala.toMap
        )
      }
    }

  case class MemoryUsage(
      init: Long,
      used: Long,
      comitted: Long,
      max: Long,
      free: Long,
      description: String
  )

  object MemoryUsage {

    def apply(init: Long, used: Long, comitted: Long, max: Long): MemoryUsage = {
      def str(n: Long) = ByteSize(n).toHuman

      val free = max - used

      val descr =
        s"init=${str(init)}, used=${str(used)}, comitted=${str(comitted)}, max=${str(max)}, free=${str(free)}"
      MemoryUsage(init, used, comitted, max, free, descr)
    }

    val empty = MemoryUsage(0, 0, 0, 0)

    def createHeap[F[_]: Sync]: F[MemoryUsage] =
      Sync[F].delay {
        val mxb  = management.ManagementFactory.getMemoryMXBean()
        val heap = mxb.getHeapMemoryUsage()
        MemoryUsage(
          init = math.max(0, heap.getInit()),
          used = math.max(0, heap.getUsed()),
          comitted = math.max(0, heap.getCommitted()),
          max = math.max(0, heap.getMax())
        )
      }

    implicit val jsonEncoder: Encoder[MemoryUsage] =
      deriveEncoder[MemoryUsage]

    implicit val jsonDecoder: Decoder[MemoryUsage] =
      deriveDecoder[MemoryUsage]
  }

  implicit val jsonEncoder: Encoder[JvmInfo] =
    deriveEncoder[JvmInfo]

  implicit val jsonDecoder: Decoder[JvmInfo] =
    deriveDecoder[JvmInfo]
}
