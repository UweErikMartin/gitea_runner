#!/bin/bash
if [ -f $GITEA_CONFIG_PATH/$GITEA_RUNNER_NAME ]; then
  cp -v $GITEA_CONFIG_PATH/$GITEA_RUNNER_NAME /var/lib/act_runner/.runner
  cp -v $GITEA_CONFIG_PATH/$GITEA_RUNNER_NAME.config.yaml /etc/act_runner/config.yaml
  chown -v -R act_runner:act_runner /var/lib/act_runner
else
  echo "Runner not registered, registering now..."
  act_runner register -c /etc/act_runner/config.yaml \
    --no-interactive \
    --instance $GITEA_INSTANCE \
    --name $GITEA_RUNNER_NAME \
    --token $GITEA_RUNNER_REGISTRATION_TOKEN
  chown -v -R act_runner:act_runner /var/lib/act_runner
  if [ -d $GITEA_CONFIG_PATH ]; then
    cp -v /var/lib/act_runner/.runner $GITEA_CONFIG_PATH/$GITEA_RUNNER_NAME
    cp -v /etc/act_runner/config.yaml $GITEA_CONFIG_PATH/$GITEA_RUNNER_NAME.config.yaml
  fi
fi

