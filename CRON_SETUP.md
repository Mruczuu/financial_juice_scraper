# NEWS SCRAPER - CRON SETUP

## CRON CONFIGURATION FOR 24/7 OPERATION

Add these lines to your crontab (`crontab -e`):

```bash
# NEWS SCRAPER - 24/7 High Impact News Monitoring
# Watchdog every 5 minutes - ensures scraper is always running
*/5 * * * * cd $HOME/news_scraper && bash news_watchdog.sh >> $HOME/logs/news_watchdog.log 2>&1

# Auto-start after reboot (wait 60 seconds for system to stabilize)
@reboot sleep 60 && cd $HOME/news_scraper && bash start_news_scraper.sh

# Optional: Daily log rotation at 2 AM (keeps logs manageable)
0 2 * * * find $HOME/logs -name "news_*.log" -size +100M -exec mv {} {}.old \; -exec touch {} \;
```

## MANUAL COMMANDS

### Start scraper:
```bash
cd ~/news_scraper && bash start_news_scraper.sh
```

### Stop scraper:
```bash
cd ~/news_scraper && bash stop_news_scraper.sh
```

### Check status:
```bash
ps aux | grep scraper.py
```

### Monitor logs:
```bash
tail -f ~/logs/news_scraper.log
tail -f ~/logs/news_watchdog.log
```

### Check recent red news in database:
```bash
# You can check Supabase dashboard or use psql/curl
```

## LOG FILES LOCATIONS

- **Main scraper output**: `~/logs/news_scraper.log`
- **Watchdog activity**: `~/logs/news_watchdog.log` 
- **Startup/shutdown**: `~/logs/news_scraper_startup.log`

## TROUBLESHOOTING

### If scraper keeps crashing:
1. Check logs: `cat ~/logs/news_scraper.log | tail -50`
2. Check system resources: `top`, `free -h`, `df -h`
3. Restart manually: `bash stop_news_scraper.sh && bash start_news_scraper.sh`

### If no red news is being detected:
1. Check if scraper is running: `ps aux | grep scraper`
2. Monitor real-time: `tail -f ~/logs/news_scraper.log`
3. Verify database connection and credentials in `.env`

### Emergency stop all:
```bash
pkill -f "scraper.py"
```