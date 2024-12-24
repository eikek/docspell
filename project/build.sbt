// Get io version from environment or fall back to a known working version
def ioVersion = sys.env
  .get("BUILD_VERSION")
  .orElse(sys.props.get("sbt.build.version"))
  .getOrElse("1.10.3")

libraryDependencies ++= Seq(
  "com.typesafe" % "config" % "1.4.3",
  // Use the determined version instead of sbtVersion.value
  "org.scala-sbt" %% "io" % ioVersion
)
