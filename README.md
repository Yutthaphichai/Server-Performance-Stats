# Server Performance Stats

A script to analyse basic server performance stats. Run it on a Linux server to see CPU, memory, disk usage, top processes by CPU and memory, plus optional info such as OS version, uptime, load average, and logged-in users.

## Requirements

- **Linux** (the script is designed for Linux with `/proc`)
- Bash
- Standard commands: `df`, `ps`, `awk`, `who` (and `grep`, `tail`, `sed`)

## Installation

```bash
git clone <repo-url>
cd Server-Performance-Stats
chmod +x server-stats.sh
```

## Usage

```bash
./server-stats.sh
```

No arguments are required — the script prints all sections in order.

## Stats reported

### Required

| Stat                                | Description                                                                 |
| ----------------------------------- | --------------------------------------------------------------------------- |
| **Total CPU usage**           | Overall CPU usage percentage (sampled from `/proc/stat` over 1 second)    |
| **Total memory usage**        | Total / used / free RAM in MB and usage percentage (from `/proc/meminfo`) |
| **Total disk usage**          | Root filesystem (`/`) total, used, free and usage % (from `df -h /`)    |
| **Top 5 processes by CPU**    | Five processes using the most CPU (`%CPU`, PID, COMMAND)                  |
| **Top 5 processes by memory** | Five processes using the most memory (`%MEM`, PID, COMMAND)               |

### Optional (stretch)

| Stat                            | Description                                                                                                                                      |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **OS version**            | OS name and version (from `/etc/os-release` or `uname`)                                                                                      |
| **Uptime & load average** | System uptime (days/hours/minutes) and 1m, 5m, 15m load (from `/proc/uptime`, `/proc/loadavg`)                                               |
| **Logged-in users**       | Currently logged-in users (from `who`)                                                                                                         |
| **Failed login attempts** | Count and sample of failed logins from `/var/log/auth.log` or `/var/log/secure` (or `lastb` if available) — may require root to read logs |

## Notes

- On **macOS** or systems without `/proc`, CPU, memory, top 5, and uptime/load sections are skipped (the script will report "Skipping" or show no output for those parts).
- Colored output is only enabled when stdout is a terminal (TTY); when piped elsewhere, no color escape codes are used.
- Check syntax with: `bash -n server-stats.sh`

## Example output (on Linux)

```
Server performance stats — Tue Mar 17 13:01:26 +07 2026

═══ Total CPU usage
  CPU usage: 12%

═══ Total memory usage
  Total: 16384 MB  |  Used: 8192 MB  |  Free: 8192 MB  |  Used: 50%

═══ Total disk usage
  Root (/): Total 50G  Used 20G  Free 28G  Usage 42%

═══ Top 5 processes by CPU usage
  %CPU  PID  COMMAND
  15.2  1234 node
  ...

═══ OS version
  Ubuntu 22.04 LTS
...
```

## License

Use as allowed by the project.
