package docspell.store

import scala.concurrent.ExecutionContext

import cats.effect._

import docspell.common.LenientUri
import docspell.store.impl.StoreImpl

import doobie._
import org.h2.jdbcx.JdbcConnectionPool

trait StoreFixture {
  def withStore(db: String)(code: Store[IO] => IO[Unit]): Unit = {
    //StoreFixture.store(StoreFixture.memoryDB(db)).use(code).unsafeRunSync()
    val jdbc  = StoreFixture.memoryDB(db)
    val xa    = StoreFixture.globalXA(jdbc)
    val store = new StoreImpl[IO](jdbc, xa)
    store.migrate.unsafeRunSync()
    code(store).unsafeRunSync()
  }

  def withXA(db: String)(code: Transactor[IO] => IO[Unit]): Unit =
    StoreFixture.makeXA(StoreFixture.memoryDB(db)).use(code).unsafeRunSync()

}

object StoreFixture {
  implicit def contextShift: ContextShift[IO] =
    IO.contextShift(ExecutionContext.global)

  def memoryDB(dbname: String): JdbcConfig =
    JdbcConfig(
      LenientUri.unsafe(
        s"jdbc:h2:mem:$dbname;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"
      ),
      "sa",
      ""
    )

  def globalXA(jdbc: JdbcConfig): Transactor[IO] =
    Transactor.fromDriverManager(
      "org.h2.Driver",
      jdbc.url.asString,
      jdbc.user,
      jdbc.password
    )

  def makeXA(jdbc: JdbcConfig): Resource[IO, Transactor[IO]] = {
    def jdbcConnPool =
      JdbcConnectionPool.create(jdbc.url.asString, jdbc.user, jdbc.password)

    val makePool = Resource.make(IO(jdbcConnPool))(cp => IO(cp.dispose()))

    for {
      ec      <- ExecutionContexts.cachedThreadPool[IO]
      blocker <- Blocker[IO]
      pool    <- makePool
      xa = Transactor.fromDataSource[IO].apply(pool, ec, blocker)
    } yield xa
  }

  def store(jdbc: JdbcConfig): Resource[IO, Store[IO]] =
    for {
      xa <- makeXA(jdbc)
      store = new StoreImpl[IO](jdbc, xa)
      _ <- Resource.eval(store.migrate)
    } yield store
}
