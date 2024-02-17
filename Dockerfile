FROM golang:1.21-alpine as prep

RUN apk --update add ca-certificates bash
RUN mkdir -p /tmp

RUN go install github.com/go-delve/delve/cmd/dlv@latest

FROM alpine:latest

ARG USER_UID=10001
USER ${USER_UID}

COPY --from=prep /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=prep /go/bin/dlv /dlv
COPY build/otelcontribcol/otelcol-contrib /

ENV DELVE_CONTINUE=true
EXPOSE 4317 55680 55679 2345
WORKDIR /
CMD ["/bin/sh", "-c", "/dlv --listen=:2345 --continue=$DELVE_CONTINUE --headless=true --api-version=2 --accept-multiclient --log --log-output=debugger exec  /otelcol-contrib --  --config /etc/otel/config.yaml"]