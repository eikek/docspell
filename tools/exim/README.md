# SMTP Gateway via Docker

This is an example setup for a SMTP server that forwards all incoming
mails to docspell via `curl`.

The docker image contains [exim](https://exim.org) and a sample config
file that runs curl against a configurable docspell url. It uses the
[integration
endpoint](https://docspell.org/doc/uploading#integration-endpoint) and
it expects it to be configured with "http-header" protection. It can
be easily adopted to use a different protection method.

Please see the [documentation
page](https://docspell.org/doc/tools/smtpgateway) for a guide.
