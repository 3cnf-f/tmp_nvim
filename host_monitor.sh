#!/bin/bash

LOG_FILE="ai_engine_telemetry.log"
echo "--- Starting Hardware & Thermal Monitor ---" | tee -a "$LOG_FILE"
printf "%-19s | %-8s | %-8s | %-11s | %-8s | %-8s | %-10s\n" "TIMESTAMP" "CPU USE" "CPU TEMP" "SYSTEM RAM" "GPU USE" "GPU TEMP" "GPU VRAM" | tee -a "$LOG_FILE"
echo "--------------------------------------------------------------------------------------" | tee -a "$LOG_FILE"

# Function to get exact CPU usage from /proc/stat
get_cpu_usage() {
    read cpu a b c previdle rest < /proc/stat
    prevtotal=$((a+b+c+previdle))
    sleep 0.5
    read cpu a b c idle rest < /proc/stat
    total=$((a+b+c+idle))
    echo "$((100 * ( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))"
}

while true; do
    TS=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Get exact CPU %
    CPU_UTIL=$(get_cpu_usage)
    
    # Get CPU Temp (Extracts integer from 'Package id 0: +45.0°C')
    CPU_TEMP=$(sensors | awk '/^Package id 0:/ {print $4}' | grep -o '[0-9]*\.[0-9]*' | cut -d. -f1)
    
    # Get System RAM
    RAM_USED=$(free -m | awk '/^Mem:/ {print $3}')
    
    # Get GPU Util, VRAM, and Temp
    GPU_DATA=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,temperature.gpu --format=csv,noheader,nounits)
    GPU_UTIL=$(echo "$GPU_DATA" | awk -F', ' '{print $1}')
    VRAM_USED=$(echo "$GPU_DATA" | awk -F', ' '{print $2}')
    GPU_TEMP=$(echo "$GPU_DATA" | awk -F', ' '{print $3}')
    
    # Print to screen AND append to log file with perfect alignment
    printf "%-19s | %-6s %% | %-6s C | %-7s MiB | %-6s %% | %-6s C | %-6s MiB\n" "$TS" "${CPU_UTIL:-0}" "${CPU_TEMP:-0}" "${RAM_USED:-0}" "${GPU_UTIL:-0}" "${GPU_TEMP:-0}" "${VRAM_USED:-0}" | tee -a "$LOG_FILE"
done
