FROM golang:1.26-alpine AS builder
WORKDIR /src

COPY go.mod ./
COPY . .

ARG VERSION=dev

RUN CGO_ENABLED=0 go build \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /server .

FROM alpine:3.22

RUN adduser -D -u 10001 appuser

COPY --from=builder /server /server

USER appuser

EXPOSE 8080

ENTRYPOINT ["/server"]