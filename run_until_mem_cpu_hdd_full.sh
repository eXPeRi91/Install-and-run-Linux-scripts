# Define parameters for each virtual machine
RAM=512
CPU=1
HDD=5

# Define T-Rex flags
TREX_FLAGS="-a algoritam -o copy_ip_from_pool -u here_wallet.here_name -p x"

# Continuously create virtual machines until memory and CPU usage limits are reached
while true; do
  # Check memory and CPU usage
  memory_usage=$(free -m | awk '/^Mem:/{print $3/$2 * 100.0}')
  cpu_usage=$(top -bn1 | awk '/Cpu/ {print $2}' | sed 's/%//')

  # If memory usage or CPU usage exceeds 90%, break the loop
  if [[ $memory_usage -gt 90 ]] || [[ $cpu_usage -gt 90 ]]; then
    break
  fi

  # Create a new virtual machine
  vm_name="vm-$RANDOM"
  virt-install \
    --name $vm_name \
    --memory $RAM \
    --vcpus $CPU \
    --disk size=$HDD \
    --graphics none \
    --os-type linux \
    --os-variant centos8 \
    --network network=default \
    --import \
    --noautoconsole

  # Attach GPU to the virtual machine
  virsh attach-device $vm_name /path/to/gpu.xml

  # Start the virtual machine and run benchmark test
  virsh start $vm_name
  result=$(ssh $vm_name "./run-benchmark.sh")
  if [ $result -ne 0 ]; then
    continue
  fi

  # Clear the virtual machine and install T-Rex
  virsh destroy $vm_name
  virsh start $vm_name
  ssh $vm_name "./clear-vm.sh && ./install-trex.sh $TREX_FLAGS"
done
