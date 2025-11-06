#!/bin/bash

# News Scraper Stop Script
# Use this to safely stop the news scraper

LOG_FILE="$HOME/logs/news_scraper_startup.log"
PYTHON_SCRIPT="scraper.py"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $1" | tee -a "$LOG_FILE"
}

log_message "🛑 Stopping News Scraper..."

# Check if running
PROCESS_COUNT=$(pgrep -f "python.*$PYTHON_SCRIPT" | wc -l)

if [ $PROCESS_COUNT -eq 0 ]; then
    log_message "ℹ️ News scraper is not running"
    exit 0
fi

# Get PIDs
PIDS=$(pgrep -f "python.*$PYTHON_SCRIPT")
log_message "📋 Found $PROCESS_COUNT process(es): $PIDS"

# Graceful shutdown first
log_message "🔄 Attempting graceful shutdown..."
pkill -TERM -f "python.*$PYTHON_SCRIPT"

# Wait for graceful shutdown
sleep 10

# Check if still running
REMAINING=$(pgrep -f "python.*$PYTHON_SCRIPT" | wc -l)

if [ $REMAINING -gt 0 ]; then
    log_message "⚠️ Processes still running. Force killing..."
    pkill -KILL -f "python.*$PYTHON_SCRIPT"
    sleep 2
fi

# Final check
FINAL_COUNT=$(pgrep -f "python.*$PYTHON_SCRIPT" | wc -l)

if [ $FINAL_COUNT -eq 0 ]; then
    log_message "✅ News scraper stopped successfully"
else
    log_message "❌ Failed to stop all processes. Manual intervention may be needed."
    exit 1
fi