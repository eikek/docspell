val sharedSettings = Seq(
  organization := "com.github.eikek",
  scalaVersion := "2.13.0",
  scalacOptions ++= Seq(
    "-deprecation",
    "-encoding", "UTF-8",
    "-language:higherKinds",
    "-language:postfixOps",
    "-feature",
    "-Ypartial-unification",
    "-Xfatal-warnings", // fail when there are warnings
    "-unchecked",
    "-Xlint",
    "-Yno-adapted-args",
    "-Ywarn-dead-code",
    "-Ywarn-numeric-widen",
    "-Ywarn-value-discard",
    "-Ywarn-unused-import"
  ),
  scalacOptions in (Compile, console) := Seq()
)

val testSettings = Seq(
  testFrameworks += new TestFramework("minitest.runner.Framework"),
  libraryDependencies ++= Dependencies.miniTest
)

val store = project.in(file("modules/store")).
  settings(sharedSettings).
  settings(testSettings).
  settings(
    name := "docspell-store",
    libraryDependencies ++=
      Dependencies.doobie ++ Dependencies.bitpeace ++ Dependencies.fs2 ++ Dependencies.databases
  )


val root = project.
  settings(sharedSettings).
  settings(
    name := "docspell-root"
  ).
  aggregate(store)
