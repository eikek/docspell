package docspell.common

object DocspellSystem {

  val user                 = Ident.unsafe("docspell-system")
  val taskGroup            = user
  val migrationTaskTracker = Ident.unsafe("full-text-index-tracker")

}
