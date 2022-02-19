import sbt._
import sbt.Keys._
import docspell.build._
import sbtcrossproject.CrossProject

object TestSettingsPlugin extends AutoPlugin {

  object autoImport {
    def inTest(d0: Seq[ModuleID], ds: Seq[ModuleID]*) =
      ds.fold(d0)(_ ++ _).map(_ % Test)

    implicit class ProjectTestSettingsSyntax(project: Project) {
      def withTestSettings =
        project.settings(testSettings)

      def withTestSettingsDependsOn(p: Project, ps: Project*) =
        (p :: ps.toList).foldLeft(project) { (cur, dep) =>
          cur.dependsOn(dep % "test->test,compile")
        }
    }

    implicit class CrossprojectTestSettingsSyntax(project: CrossProject) {
      def withTestSettings =
        project.settings(testSettings)
    }

  }

  import autoImport._

  val testSettings = Seq(
    libraryDependencies ++= inTest(Dependencies.munit, Dependencies.scribe),
    testFrameworks += new TestFramework("munit.Framework")
  )

}
