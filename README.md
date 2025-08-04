# JavaAutoDump
A Bash script to automatically take a Java heap and thread dump when the Java application's REST service becomes unresponsive.

It uses curl for the HTTPS check (with timeout), and jcmd (built-in with the JDK) for heap and thread dumps. Both the check interval and timeout are configurable via variables at the top.
The script runs in an infinite loop in the background, logging each check and only performing dumps if the service is down.

## Notes:
### Configuration:
Set `REST_URL`, `CHECK_TIMEOUT`, `CHECK_INTERVAL`, `LOG_FILE`, and `DUMP_DIR` as needed.
For finding your Java PID, either use a PID file or set a unique process pattern.

### Background Execution:
To run in the background:
`nohup bash yourscript.sh &`
Or use `systemd/screen/tmux` for production.

### Permissions:
The script assumes your user can run jcmd and write to log/dump locations.

### Customizations:
Replace the Java PID logic if your setup differs.
You can use `jmap` and `jstack` instead of `jcmd` if your JDK doesn’t have jcmd.
