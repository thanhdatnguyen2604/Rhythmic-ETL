#!/bin/bash

# Script điều khiển bật/tắt VM trên GCP để tiết kiệm chi phí
# Cần cài đặt Google Cloud SDK và đăng nhập trước khi chạy script

# Xác định các biến
PROJECT_ID=$1
ZONE=$2
ACTION=$3
VM_PATTERN=${4:-"all"}

if [ -z "$PROJECT_ID" ] || [ -z "$ZONE" ] || [ -z "$ACTION" ]; then
  echo "Sử dụng: $0 <project_id> <zone> <start|stop> [vm_pattern]"
  echo "Ví dụ: $0 my-project-id us-central1-a stop"
  echo "Ví dụ (chỉ định VM): $0 my-project-id us-central1-a start kafka"
  exit 1
fi

# Kiểm tra hành động hợp lệ
if [ "$ACTION" != "start" ] && [ "$ACTION" != "stop" ]; then
  echo "Hành động không hợp lệ. Hãy sử dụng 'start' hoặc 'stop'."
  exit 1
fi

# Cấu hình project
gcloud config set project $PROJECT_ID

# Lấy danh sách VM
if [ "$VM_PATTERN" == "all" ]; then
  VMS=$(gcloud compute instances list --filter="zone:($ZONE)" --format="value(name)")
else
  VMS=$(gcloud compute instances list --filter="zone:($ZONE) AND name~$VM_PATTERN" --format="value(name)")
fi

# Kiểm tra danh sách VM
if [ -z "$VMS" ]; then
  echo "Không tìm thấy VM nào phù hợp với mẫu '$VM_PATTERN' trong zone '$ZONE'."
  exit 1
fi

# Thực hiện hành động trên VM
for VM in $VMS; do
  echo "Đang $ACTION VM: $VM..."
  gcloud compute instances $ACTION $VM --zone=$ZONE --quiet
  
  if [ $? -eq 0 ]; then
    echo "Thành công: $VM đã được $ACTION."
  else
    echo "Lỗi: Không thể $ACTION VM $VM."
  fi
done

echo "Hoàn tất!"

# Kiểm tra trạng thái VM sau khi thực hiện
echo "Trạng thái VM hiện tại:"
if [ "$VM_PATTERN" == "all" ]; then
  gcloud compute instances list --filter="zone:($ZONE)" --format="table(name,status)"
else
  gcloud compute instances list --filter="zone:($ZONE) AND name~$VM_PATTERN" --format="table(name,status)"
fi 