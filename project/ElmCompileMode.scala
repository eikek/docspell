trait ElmCompileMode {
  def flags: Seq[String]
}
object ElmCompileMode {
  case object Production extends ElmCompileMode {
    val flags = Seq("--optimize")
  }
  case object Debug extends ElmCompileMode {
    val flags = Seq("--debug")
  }
  case object Dev extends ElmCompileMode {
    val flags = Seq.empty
  }
}
