FROM alpine:latest
LABEL maintainer="eikek0 <eike@docspell.org>"

ENV DB_TYPE=postgresql \
  DB_HOST=db \
  DB_PORT=5432 \
  DB_NAME=dbname \
  DB_USER=dbuser \
  DB_PASS=dbpass
