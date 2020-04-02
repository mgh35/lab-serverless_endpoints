#!/bin/bash
set -e


if [ -z "${SUBSCRIPTION_ID}" ]; then
  echo "Must specify SUBSCRIPTION_ID"
  exit 1
fi

SERVICE_PRINCIPLE=$(az ad sp create-for-rbac -n "postboard-admin" --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
APP_ID=$(echo $SERVICE_PRINCIPLE | grep appId | awk -F'"' '{print $4}')
PASSWORD=$(echo $SERVICE_PRINCIPLE | grep password | awk -F'"' '{print $4}')
TENANT=$(echo $SERVICE_PRINCIPLE | grep tenant | awk -F'"' '{print $4}')

echo $SERVICE_PRINCIPLE

mkdir ~/.azure-postboard
cat > ~/.azure-postboard/env.sh <<EOF
if [[ $SHELL =~ '/zsh' ]]; then
  read -rs 'pw?Password: '
else
  read -s -p "Password: " pw
fi
echo ""

echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
export ARM_CLIENT_ID=${APP_ID}
export ARM_CLIENT_SECRET=\$pw
export ARM_TENANT_ID=${TENANT}

# Not needed for public, required for usgovernment, german, china
export ARM_ENVIRONMENT=public
EOF
chmod +x ~/.azure-postboard/env.sh

echo "Remember to record the password. To setup terraform, run `source ~/.azure-postboard/env.sh` an then enter that password."
