#!/bin/bash

# Set daily budget alert for GCP
# Ensure Google Cloud SDK is installed and logged in before running script

# Determine variables
PROJECT_ID=$1
BUDGET_AMOUNT=$2
EMAIL=$3

if [ -z "$PROJECT_ID" ] || [ -z "$BUDGET_AMOUNT" ] || [ -z "$EMAIL" ]; then
  echo "Usage: $0 <project_id> <budget_amount_in_USD> <email>"
  echo "Example: $0 my-project-id 5 example@gmail.com"
  exit 1
fi

echo "Setting budget alert for project: $PROJECT_ID"
echo "Budget: $BUDGET_AMOUNT USD per day"
echo "Alert email: $EMAIL"

# Create temporary budget JSON configuration file
cat > /tmp/budget.json << EOF
{
  "displayName": "Daily Budget",
  "amount": {
    "specifiedAmount": {
      "currencyCode": "USD",
      "units": "$BUDGET_AMOUNT"
    }
  },
  "budgetFilter": {
    "projects": ["projects/$PROJECT_ID"]
  },
  "thresholdRules": [
    {
      "thresholdPercent": 0.5,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 0.8,
      "spendBasis": "CURRENT_SPEND"
    },
    {
      "thresholdPercent": 1.0,
      "spendBasis": "CURRENT_SPEND"
    }
  ],
  "notificationsRule": {
    "monitoringNotificationChannels": [],
    "pubsubTopic": "",
    "schemaVersion": "1.0",
    "disableDefaultNotifications": false
  },
  "etag": ""
}
EOF

# Create email notification channel
CHANNEL_ID=$(gcloud alpha monitoring channels create --display-name="Budget Alert Email" --type=email --channel-labels=email_address=$EMAIL --format="value(name)")

# Update configuration file with notification channel
sed -i.bak "s|\"monitoringNotificationChannels\": \[\],|\"monitoringNotificationChannels\": \[\"$CHANNEL_ID\"\],|g" /tmp/budget.json

# Create budget using Billing API
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @/tmp/budget.json \
  https://billingbudgets.googleapis.com/v1/billingAccounts/$(gcloud billing accounts list --format="value(name)")/budgets

echo "Budget alert setup complete!"
echo "Check alert settings at: https://console.cloud.google.com/billing/budgets"

# Delete temporary files
rm /tmp/budget.json /tmp/budget.json.bak 