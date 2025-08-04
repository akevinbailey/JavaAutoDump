#!/bin/bash

# ====================== CONFIGURATION ======================

# The HTTPS URL of the REST service to check
REST_URL="https://localhost:8443/your/rest/endpoint"

# Timeout in seconds for the REST check (connection + read)
CHECK_TIMEOUT=5

# How often to check the service (seconds)
CHECK_INTERVAL=30

# Full path to the log file
LOG_FILE="/var/log/rest_service_monitor.log"

# Java application's process ID or a pattern to find it
JAVA_PID_FILE="/var/run/yourapp.pid"   # If you track the PID
# Or, if you need to grep for the process:
JAVA_PROC_PATTERN="YourMainClassName"  # Set to your Java main class

# Where to store the dumps
DUMP_DIR="/var/log/java_dumps"
mkdir -p "$DUMP_DIR"

# ==================== END CONFIGURATION ====================

# Function to get Java PID (edit for your situation)
get_java_pid() {
    if [ -f "$JAVA_PID_FILE" ]; then
        cat "$JAVA_PID_FILE"
    else
        # This will pick the first matching Java process
        pgrep -f "$JAVA_PROC_PATTERN" | head -n 1
    fi
}

# Main monitoring loop
while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    # REST service check
    curl -sk --max-time "$CHECK_TIMEOUT" "$REST_URL" > /dev/null 2>&1
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        echo "INFO  [$TIMESTAMP] REST service check succeeded." >> "$LOG_FILE"
    else
        echo "ERROR [$TIMESTAMP] REST service check FAILED (status: $STATUS)." >> "$LOG_FILE"

        # Do heap and thread dump
        JAVA_PID=$(get_java_pid)
        if [ -n "$JAVA_PID" ]; then
            DUMP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            HEAP_DUMP="$DUMP_DIR/heapdump_${JAVA_PID}_$DUMP_TIMESTAMP.hprof"
            THREAD_DUMP="$DUMP_DIR/threaddump_${JAVA_PID}_$DUMP_TIMESTAMP.txt"

            # Heap dump (requires JDK)
            jcmd "$JAVA_PID" GC.heap_dump "$HEAP_DUMP"
            # Thread dump
            jcmd "$JAVA_PID" Thread.print > "$THREAD_DUMP"

            echo "ERROR [$TIMESTAMP] Heap dump: $HEAP_DUMP; Thread dump: $THREAD_DUMP" >> "$LOG_FILE"
        else
            echo "ERROR [$TIMESTAMP] Java process not found; dumps not created." >> "$LOG_FILE"
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
