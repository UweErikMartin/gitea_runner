FROM alpine:latest

ARG TARGETARCH

USER root

RUN apk add --no-cache \
	ca-certificates \
	curl \
	git \
  	jq \
	bash \
  	xz \
	docker-cli \
	nodejs \
	npm

# Download latest act_runner from gitea.com releases
# (we query the Gitea API for the latest tag, then download the right arch asset)
RUN set -eux; \
    api="https://gitea.com/api/v1/repos/gitea/act_runner/releases/latest"; \
    tag="$(curl -fsSL "$api" | jq -r .tag_name)"; \
    ver="${tag#v}"; \
    case "${TARGETARCH:-amd64}" in \
      amd64) arch="amd64" ;; \
      arm64) arch="arm64" ;; \
      *) echo "Unsupported TARGETARCH=${TARGETARCH}"; exit 1 ;; \
    esac; \
    url="https://gitea.com/gitea/act_runner/releases/download/${tag}/act_runner-${ver}-linux-${arch}.xz"; \
    curl -fsSL "$url" -o /tmp/act_runner.xz; \
    xz -d /tmp/act_runner.xz; \
    install -m 0755 /tmp/act_runner /usr/local/bin/act_runner; \
    rm -f /tmp/act_runner; \
    act_runner --version || true

RUN addgroup -S act_runner \
    && adduser -S -G act_runner -h /var/lib/act_runner -s /sbin/nologin act_runner \
    && mkdir -p /var/lib/act_runner

COPY ./config.yaml /etc/act_runner/config.yaml
COPY ./register.sh /usr/local/bin/register.sh
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN chmod +x /usr/local/bin/register.sh
# add the user for the runner
ENTRYPOINT [ "/entrypoint.sh" ]