#!/bin/bash

# News Scraper Watchdog - Ensures 24/7 operation
# Checks every 5 minutes if news scraper is running, restarts if crashed

LOG_FILE="$HOME/logs/news_watchdog.log"
SCRIPT_DIR="$HOME/news_scraper"
PYTHON_SCRIPT="scraper.py"

# Create logs directory if it doesn't exist
mkdir -p "$HOME/logs"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $1" | tee -a "$LOG_FILE"
}

log_message "🔍 Watchdog check started"

# Check if news scraper process is running
PROCESS_COUNT=$(pgrep -f "python.*$PYTHON_SCRIPT" | wc -l)

if [ $PROCESS_COUNT -eq 0 ]; then
    log_message "🚨 News scraper not running. Starting..."
    
    # Change to script directory
    cd "$SCRIPT_DIR" || {
        log_message "❌ Failed to change to script directory: $SCRIPT_DIR"
        exit 1
    }
    
    # Kill any zombie processes just in case
    pkill -f "python.*$PYTHON_SCRIPT" 2>/dev/null
    
    # Start the scraper in background
    nohup python3 "$PYTHON_SCRIPT" >> "$HOME/logs/news_scraper.log" 2>&1 &
    
    # Wait a moment and check if it started
    sleep 5
    NEW_PROCESS_COUNT=$(pgrep -f "python.*$PYTHON_SCRIPT" | wc -l)
    
    if [ $NEW_PROCESS_COUNT -gt 0 ]; then
        PID=$(pgrep -f "python.*$PYTHON_SCRIPT" | head -1)
        log_message "✅ News scraper restarted successfully (PID: $PID)"
    else
        log_message "❌ Failed to restart news scraper"
        exit 1
    fi
    
elif [ $PROCESS_COUNT -eq 1 ]; then
    PID=$(pgrep -f "python.*$PYTHON_SCRIPT")
    log_message "✅ News scraper running normally (PID: $PID)"
    
else
    log_message "⚠️ Multiple news scraper processes detected ($PROCESS_COUNT). Cleaning up..."
    # Kill all but keep one
    pkill -f "python.*$PYTHON_SCRIPT"
    sleep 2
    
    # Restart single instance
    cd "$SCRIPT_DIR"
    nohup python3 "$PYTHON_SCRIPT" >> "$HOME/logs/news_scraper.log" 2>&1 &
    PID=$(pgrep -f "python.*$PYTHON_SCRIPT")
    log_message "✅ Cleaned up and restarted single instance (PID: $PID)"
fi

log_message "✅ Watchdog check completed"