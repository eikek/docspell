import sbt._
import sbt.Keys._
import docspell.build._
import sbtcrossproject.CrossProject

object TestSettingsPlugin extends AutoPlugin {

  object autoImport {
    def inTest(d0: Seq[ModuleID], ds: Seq[ModuleID]*) =
      ds.fold(d0)(_ ++ _).map(_ % Test)

    implicit class ProjectTestSettingsSyntax(project: Project) {
      def withTestSettings: Project =
        project.settings(testSettings)

      def withTestSettingsDependsOn(p: Project, ps: Project*): Project =
        withTestSettings.dependsOn((p +: ps).map(_ % "test->test"): _*)
    }

    implicit class CrossprojectTestSettingsSyntax(project: CrossProject) {
      def withTestSettings =
        project.settings(testSettings)
    }

  }

  import autoImport._

  val testSettings = Seq(
    libraryDependencies ++= (Dependencies.munit ++ Dependencies.scribe).map(_ % Test),
    testFrameworks += TestFrameworks.MUnit
  )

}
