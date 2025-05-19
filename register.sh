#!/bin/bash
token_name=$(echo ${GITEA_RUNNER_NAME^^} | tr "-" "_")_REGISTRATION_TOKEN
echo "Runner not registered, registering now..."
act_runner register -c /etc/act_runner/config.yaml \
  --no-interactive \
  --instance $GITEA_INSTANCE \
  --name $GITEA_RUNNER_NAME \
  --labels $GITEA_RUNNER_LABELS \
  --token ${!token_name}
chown -v -R act_runner:act_runner /var/lib/act_runner
