#!/bin/bash

# Script to control VM on GCP to save costs
# Ensure Google Cloud SDK is installed and logged in before running script

# Determine variables
PROJECT_ID=$1
ZONE=$2
ACTION=$3
VM_PATTERN=${4:-"all"}

if [ -z "$PROJECT_ID" ] || [ -z "$ZONE" ] || [ -z "$ACTION" ]; then
  echo "Usage: $0 <project_id> <zone> <start|stop> [vm_pattern]"
  echo "Example: $0 my-project-id us-central1-a stop"
  echo "Example (specify VM): $0 my-project-id us-central1-a start kafka"
  exit 1
fi

# Check valid action
if [ "$ACTION" != "start" ] && [ "$ACTION" != "stop" ]; then
  echo "Invalid action. Use 'start' or 'stop'."
  exit 1
fi

# Configure project
gcloud config set project $PROJECT_ID

# Get list of VMs
if [ "$VM_PATTERN" == "all" ]; then
  VMS=$(gcloud compute instances list --filter="zone:($ZONE)" --format="value(name)")
else
  VMS=$(gcloud compute instances list --filter="zone:($ZONE) AND name~$VM_PATTERN" --format="value(name)")
fi

# Check VM list
if [ -z "$VMS" ]; then
  echo "No VMs found matching pattern '$VM_PATTERN' in zone '$ZONE'."
  exit 1
fi

# Perform action on VMs
for VM in $VMS; do
  echo "Starting $ACTION VM: $VM..."
  gcloud compute instances $ACTION $VM --zone=$ZONE --quiet
  
  if [ $? -eq 0 ]; then
    echo "Success: $VM has been $ACTION."
  else
    echo "Error: Unable to $ACTION VM $VM."
  fi
done

echo "Completed!"

# Check VM status after action
echo "Current VM status:"
if [ "$VM_PATTERN" == "all" ]; then
  gcloud compute instances list --filter="zone:($ZONE)" --format="table(name,status)"
else
  gcloud compute instances list --filter="zone:($ZONE) AND name~$VM_PATTERN" --format="table(name,status)"
fi 