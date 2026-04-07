# ---- Build stage ----
FROM golang:1.21-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache \
    git \
    musl-dev \
    gcc \
    linux-headers

# 设置源码路径
WORKDIR /src

# 获取 Tailscale 最新源码
RUN git clone https://github.com/tailscale/tailscale.git .

# 切换到最新 commit（默认已在主分支）
# 如果需要指定某个 commit，可以取消下面一行注释并修改
# RUN git checkout <your-desired-commit-hash>

# 设置 Go 环境
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# 拉取依赖并构建
RUN go mod download

# 编译静态二进制
RUN go build -trimpath -ldflags="-s -w" -o /tailscaled ./cmd/tailscaled

# ---- Final stage ----
FROM alpine:latest

# 拷贝静态二进制
COPY --from=builder /tailscaled /usr/local/bin/tailscaled

# 可选：如果需要 tailscale CLI 一起打包
# COPY --from=builder /src/cmd/tailscale/tailscale /usr/local/bin/tailscale

# 运行用户
USER nobody:nobody

ENTRYPOINT ["/usr/local/bin/tailscaled"]
CMD ["--help"]
