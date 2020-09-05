package docspell.common

import io.circe.{Decoder, Encoder}

sealed trait JobState { self: Product =>
  def name: String =
    productPrefix.toLowerCase
}

object JobState {

  /** Waiting for being executed. */
  case object Waiting extends JobState {}

  def waiting: JobState = Waiting

  /** A scheduler has picked up this job and will pass it to the next
    * free slot.
    */
  case object Scheduled extends JobState {}

  /** Is currently executing */
  case object Running extends JobState {}

  /** Task completed with failure and is being retried. */
  case object Stuck extends JobState {}

  /** Finished finally with a failure */
  case object Failed extends JobState {}

  /** Finished by cancellation. */
  case object Cancelled extends JobState {}

  /** Finished with success */
  case object Success extends JobState {}

  val all: Set[JobState] =
    Set(Waiting, Scheduled, Running, Stuck, Failed, Cancelled, Success)
  val queued: Set[JobState]     = Set(Waiting, Scheduled, Stuck)
  val done: Set[JobState]       = Set(Failed, Cancelled, Success)
  val inProgress: Set[JobState] = Set(Scheduled, Running, Stuck)

  def parse(str: String): Either[String, JobState] =
    str.toLowerCase match {
      case "waiting"   => Right(Waiting)
      case "scheduled" => Right(Scheduled)
      case "running"   => Right(Running)
      case "stuck"     => Right(Stuck)
      case "failed"    => Right(Failed)
      case "cancelled" => Right(Cancelled)
      case "success"   => Right(Success)
      case _           => Left(s"Not a job state: $str")
    }

  def unsafe(str: String): JobState =
    parse(str).fold(sys.error, identity)

  def asString(state: JobState): String =
    state.name

  implicit val jobStateEncoder: Encoder[JobState] =
    Encoder.encodeString.contramap(_.name)

  implicit val jobStateDecoder: Decoder[JobState] =
    Decoder.decodeString.emap(JobState.parse)

}
