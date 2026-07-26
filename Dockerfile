# Build stage
FROM golang:1.24-alpine AS build
WORKDIR /src
RUN apk add --no-cache git
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build \
    -ldflags "-X main.version=$(git describe --tags --always --dirty 2>/dev/null || echo docker)" \
    -o /out/concordd ./cmd/concordd

# Runtime stage
FROM alpine:3.20
RUN adduser -D -u 10001 concord
COPY --from=build /out/concordd /usr/local/bin/concordd
USER concord
ENTRYPOINT ["concordd"]
CMD ["help"]
