#!/bin/sh
set -eu

# echo "Starting Docker daemon..."

# Start Docker daemon (DinD)
# DOCKERD_LOG="${DOCKERD_LOG:-/tmp/dockerd.log}"
# : >"$DOCKERD_LOG"
# /usr/local/bin/dockerd-entrypoint.sh >"$DOCKERD_LOG" 2>&1 &

# Wait until Docker is ready
# i=0
# until docker info >/dev/null 2>&1; do
#   i=$((i+1))
#   if [ "$i" -gt 60 ]; then
#     echo "Docker did not start. Last dockerd logs:"
#     tail -200 "$DOCKERD_LOG" || true
#     exit 1
#   fi
#   sleep 1
# done

# echo "Docker daemon started."

: "${GITEA_CONFIG_PATH:=}"
: "${GITEA_RUNNER_NAME:=}"

runner_file="${GITEA_CONFIG_PATH%/}/${GITEA_RUNNER_NAME}"

if [ -n "$GITEA_CONFIG_PATH" ] && [ -n "$GITEA_RUNNER_NAME" ] && [ -f "$runner_file" ]; then
  cp "$runner_file" /var/lib/act_runner/.runner
  if [ "$(id -u)" = "0" ]; then chown -R act_runner:act_runner /var/lib/act_runner; fi
else
  echo "Runner not registered, registering now..."
  act_runner register -c /etc/act_runner/config.yaml \
    --no-interactive \
    --instance "${GITEA_INSTANCE}" \
    --name "${GITEA_RUNNER_NAME}" \
    --labels "${GITEA_RUNNER_LABELS}" \
    --token "${GITEA_RUNNER_REGISTRATION_TOKEN}"
  if [ "$(id -u)" = "0" ]; then chown -R act_runner:act_runner /var/lib/act_runner; fi
  if [ -n "$GITEA_CONFIG_PATH" ] && [ -d "$GITEA_CONFIG_PATH" ] && [ -n "$GITEA_RUNNER_NAME" ]; then
    cp /var/lib/act_runner/.runner "$runner_file"
  fi
fi

echo "Starting act_runner..."
act_runner --version
exec /usr/local/bin/act_runner daemon --config /etc/act_runner/config.yaml