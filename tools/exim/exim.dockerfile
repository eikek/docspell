FROM alpine:latest

RUN apk add --no-cache exim curl
USER exim
COPY ./exim.conf /etc/exim/
EXPOSE 25
ENTRYPOINT ["exim"]
CMD ["-bdf", "-v", "-q1m"]
