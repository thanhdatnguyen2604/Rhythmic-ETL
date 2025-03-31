#!/bin/bash

# Thiết lập cảnh báo ngân sách hàng ngày cho GCP
# Cần cài đặt Google Cloud SDK và đăng nhập trước khi chạy script

# Xác định các biến
PROJECT_ID=$1
BUDGET_AMOUNT=$2
EMAIL=$3

if [ -z "$PROJECT_ID" ] || [ -z "$BUDGET_AMOUNT" ] || [ -z "$EMAIL" ]; then
  echo "Sử dụng: $0 <project_id> <budget_amount_in_USD> <email>"
  echo "Ví dụ: $0 my-project-id 5 example@gmail.com"
  exit 1
fi

echo "Thiết lập cảnh báo ngân sách cho project: $PROJECT_ID"
echo "Mức ngân sách: $BUDGET_AMOUNT USD mỗi ngày"
echo "Email cảnh báo: $EMAIL"

# Tạo file cấu hình ngân sách JSON tạm thời
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

# Tạo notification channel cho email
CHANNEL_ID=$(gcloud alpha monitoring channels create --display-name="Budget Alert Email" --type=email --channel-labels=email_address=$EMAIL --format="value(name)")

# Cập nhật file cấu hình với notification channel
sed -i.bak "s|\"monitoringNotificationChannels\": \[\],|\"monitoringNotificationChannels\": \[\"$CHANNEL_ID\"\],|g" /tmp/budget.json

# Tạo ngân sách bằng Billing API
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d @/tmp/budget.json \
  https://billingbudgets.googleapis.com/v1/billingAccounts/$(gcloud billing accounts list --format="value(name)")/budgets

echo "Thiết lập cảnh báo ngân sách hoàn tất!"
echo "Kiểm tra cài đặt cảnh báo tại: https://console.cloud.google.com/billing/budgets"

# Xóa file tạm
rm /tmp/budget.json /tmp/budget.json.bak 