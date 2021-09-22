package docspell.build

import sbt.{Def, _}
import sbt.Keys._

/** Take some files from dependencies and put them into the resources of a local sbt
  * project.
  *
  * The reason is that the stanford ner model files are very very large: the jar file for
  * the english models is about 1G and the jar file for the german models is about 170M.
  * But I only need one file that is about 60M from each jar. So just for the sake to save
  * 1GB file size when packaging docspell, this ugly plugin exists….
  *
  * The jar files to filter must be added to the libraryDependencies in config
  * "NerModels".
  */
object NerModelsPlugin extends AutoPlugin {

  object autoImport {
    val NerModels = config("NerModels")

    val nerModelsFilter = settingKey[String => Boolean]("Which files to keep.")
    val nerModelsRunFilter = taskKey[Seq[File]]("Extract files from libraryDependencies")

  }

  import autoImport._

  def nerModelSettings: Seq[Setting[_]] =
    Seq(
      nerModelsFilter := (_ => false),
      nerModelsRunFilter := {
        filterArtifacts(
          streams.value.log,
          Classpaths.managedJars(NerModels, Set("jar", "zip"), update.value),
          nerModelsFilter.value,
          (Compile / resourceManaged).value
        )
      },
      Compile / resourceGenerators += nerModelsRunFilter.taskValue
    )

  def nerClassifierSettings: Seq[Setting[_]] =
    Seq(
      libraryDependencies ++= Dependencies.stanfordNlpModels.map(_ % NerModels),
      nerModelsFilter := { name =>
        nerModels.exists(name.endsWith)
      }
    )

  override def projectConfigurations: Seq[Configuration] =
    Seq(NerModels)

  override def projectSettings: Seq[Setting[_]] =
    nerModelSettings

  def filterArtifacts(
      logger: Logger,
      cp: Classpath,
      nameFilter: NameFilter,
      out: File
  ): Seq[File] = {
    logger.info(s"NerModels: Filtering artifacts...")
    cp.files.flatMap { f =>
      IO.unzip(f, out, nameFilter)
    }
  }

  private val nerModels = List(
    "german.distsim.crf.ser.gz",
    "english.conll.4class.distsim.crf.ser.gz",
    "french-wikiner-4class.crf.ser.gz",
    "french-mwt-statistical.tsv",
    "french-mwt.tagger",
    "french-mwt.tsv",
    "german-mwt.tsv",
    "german-ud.tagger",
    "german-ud.tagger.props",
    "french-ud.tagger",
    "french-ud.tagger.props",
    "english-left3words-distsim.tagger",
    "english-left3words-distsim.tagger.props"
  )
}
