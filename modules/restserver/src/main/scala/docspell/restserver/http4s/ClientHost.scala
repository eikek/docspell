package docspell.restserver.http4s

import org.http4s._
import org.http4s.headers._
import org.http4s.util.CaseInsensitiveString

/** Obtain the host name of the client from the request.
  */
object ClientHost {

  def get[F[_]](req: Request[F]): Option[String] =
    xForwardedFor(req)
      .orElse(xForwardedHost(req))
      .orElse(host(req))

  private def host[F[_]](req: Request[F]): Option[String] =
    req.headers.get(Host).map(_.host)

  private def xForwardedFor[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(`X-Forwarded-For`)
      .flatMap(_.values.head)
      .flatMap(inet => Option(inet.getHostName).orElse(Option(inet.getHostAddress)))

  private def xForwardedHost[F[_]](req: Request[F]): Option[String] =
    req.headers
      .get(CaseInsensitiveString("X-Forwarded-Host"))
      .map(_.value)
}
