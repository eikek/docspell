import sbt._
import com.typesafe.config._

import scala.annotation.tailrec
import scala.jdk.CollectionConverters._
import java.util.{Map => JMap}

object EnvConfig {
  def serializeTo(cfg: Config, out: File): Unit =
    IO.write(out, serialize(cfg))

  def serialize(cfg: Config): String = {
    val buffer = new StringBuilder
    buffer.append("#### Server Configuration ####\n")
    for (
      entry <- cfg.entrySet().asScala.toList.sortBy(_.getKey)
      if isValidKey("docspell.server", entry)
    ) append(buffer, entry.getKey, entry.getValue)

    buffer.append("\n#### JOEX Configuration ####\n")
    for (
      entry <- cfg.entrySet().asScala.toList.sortBy(_.getKey)
      if isValidKey("docspell.joex", entry)
    ) append(buffer, entry.getKey, entry.getValue)

    buffer.toString().trim
  }

  private def append(buffer: StringBuilder, key: String, value: ConfigValue): Unit = {
    if (value.origin().comments().asScala.nonEmpty) {
      buffer.append("\n")
    }
    value
      .origin()
      .comments()
      .forEach(c => buffer.append("# ").append(c).append("\n"))
    buffer.append(keyToEnv(key)).append("=").append(value.render()).append("\n")
  }

  def isValidKey(prefix: String, entry: JMap.Entry[String, ConfigValue]): Boolean =
    entry.getKey
      .startsWith(prefix) && entry.getValue.valueType() != ConfigValueType.LIST

  def makeConfig(files: List[File]): Config =
    files
      .foldLeft(ConfigFactory.empty()) { (cfg, file) =>
        val cf = ConfigFactory.parseFile(file)
        cfg.withFallback(cf)
      }
      .withFallback(ConfigFactory.defaultOverrides(getClass.getClassLoader))
      .resolve()

  def makeConfig(file: File, files: File*): Config =
    makeConfig(file :: files.toList)

  def keyToEnv(k: String): String = {
    val buffer = new StringBuilder
    val len = k.length

    @tailrec
    def go(current: Int): String =
      if (current >= len) buffer.toString()
      else {
        k.charAt(current) match {
          case '.' => buffer.append("_")
          case '-' => buffer.append("__")
          case '_' => buffer.append("___")
          case c   => buffer.append(c.toUpper)
        }
        go(current + 1)
      }

    go(0)
  }
}
