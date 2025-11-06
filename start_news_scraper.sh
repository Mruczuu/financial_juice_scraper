#!/bin/bash

# News Scraper Startup Script
# Use this to manually start the news scraper

LOG_FILE="$HOME/logs/news_scraper_startup.log"
SCRIPT_DIR="$HOME/news_scraper"
PYTHON_SCRIPT="scraper.py"

# Create logs directory
mkdir -p "$HOME/logs"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $1" | tee -a "$LOG_FILE"
}

log_message "🚀 Starting News Scraper..."

# Change to script directory
cd "$SCRIPT_DIR" || {
    log_message "❌ Failed to change to directory: $SCRIPT_DIR"
    exit 1
}

# Kill any existing instances
log_message "🧹 Cleaning up any existing processes..."
pkill -f "python.*$PYTHON_SCRIPT" 2>/dev/null
sleep 2

# Check if requirements are met
if [ ! -f "$PYTHON_SCRIPT" ]; then
    log_message "❌ Script not found: $PYTHON_SCRIPT"
    exit 1
fi

if [ ! -f ".env" ]; then
    log_message "❌ Environment file not found: .env"
    exit 1
fi

# Start the scraper
log_message "🔄 Starting news scraper in background..."
nohup python3 "$PYTHON_SCRIPT" >> "$HOME/logs/news_scraper.log" 2>&1 &

# Wait and verify startup
sleep 5
PROCESS_COUNT=$(pgrep -f "python.*$PYTHON_SCRIPT" | wc -l)

if [ $PROCESS_COUNT -gt 0 ]; then
    PID=$(pgrep -f "python.*$PYTHON_SCRIPT" | head -1)
    log_message "✅ News scraper started successfully (PID: $PID)"
    log_message "📊 Monitor logs: tail -f $HOME/logs/news_scraper.log"
    log_message "🔍 Check process: ps aux | grep scraper.py"
else
    log_message "❌ Failed to start news scraper"
    log_message "📋 Check logs: cat $HOME/logs/news_scraper.log"
    exit 1
fi