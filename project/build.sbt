libraryDependencies ++= Seq(
  "com.typesafe" % "config" % "1.4.3",
  // sbt-native-packager and sbt-github-pages pull in an incompatible
  // version of sbt-io which will break the build as soon as the
  // sbt-bloop plugin is also present
  "org.scala-sbt" %% "io" % sbtVersion.value
)
