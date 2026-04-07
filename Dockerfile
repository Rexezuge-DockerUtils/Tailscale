FROM golang:alpine AS builder

ARG TARGETARCH

RUN apk add --no-cache git

RUN LATEST_TAG=$(wget -qO- "https://api.github.com/repos/tailscale/tailscale/releases/latest" \
    | grep -m1 '"tag_name"' | cut -d'"' -f4) && \
    git clone --depth 1 --branch "${LATEST_TAG}" https://github.com/tailscale/tailscale.git /src && \
    echo "${LATEST_TAG}" > /src/.version_tag

WORKDIR /src

RUN VERSION_TAG=$(cat .version_tag) && \
    VERSION_SHORT="${VERSION_TAG#v}" && \
    VERSION_LONG="${VERSION_SHORT}-t$(git rev-parse --short HEAD)" && \
    CGO_ENABLED=0 GOARCH=${TARGETARCH} go build -o /out/tailscale \
      -ldflags "-s -w -extldflags '-static' -X tailscale.com/version.longStamp=${VERSION_LONG} -X tailscale.com/version.shortStamp=${VERSION_SHORT}" \
      ./cmd/tailscale && \
    CGO_ENABLED=0 GOARCH=${TARGETARCH} go build -o /out/tailscaled \
      -ldflags "-s -w -extldflags '-static' -X tailscale.com/version.longStamp=${VERSION_LONG} -X tailscale.com/version.shortStamp=${VERSION_SHORT}" \
      ./cmd/tailscaled

FROM scratch
COPY --from=builder /out/tailscale /usr/local/bin/tailscale
COPY --from=builder /out/tailscaled /usr/local/bin/tailscaled
ENTRYPOINT ["/usr/local/bin/tailscaled"]
