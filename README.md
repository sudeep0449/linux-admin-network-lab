# Linux System & Network Administration Lab

A hands-on lab covering core Linux system administration and network administration skills, built and tested entirely on a self-provisioned Ubuntu Desktop virtual machine. Every command below was actually run and verified on a live system — this includes real troubleshooting notes from issues hit along the way, not just a clean happy-path writeup.

## Environment

- **OS:** Ubuntu 26.04 LTS Desktop
- **Hypervisor:** VirtualBox (Windows host)
- **Networking:** VirtualBox NAT network (`10.0.2.0/24`)
- VirtualBox Guest Additions installed for host/guest clipboard integration

## Topics Covered

### 1. Filesystem, Permissions & Users

| Command | Purpose |
|---|---|
| `ls -la` | List files with permissions, ownership, and hidden files |
| `chmod 700 <dir>` | Restrict a directory to owner-only access (octal: read=4, write=2, execute=1) |
| `useradd -m <user>` | Create a new user with a home directory |
| `passwd <user>` | Set/change a user's password |
| `usermod -aG sudo <user>` | Grant sudo access without overwriting existing group memberships |

Explored `/etc/passwd` and `/etc/group` field structure, and the difference between `sudo <cmd>` (authenticates the invoking user, run once as root) vs. a full root shell.

### 2. Processes & Services

| Command | Purpose |
|---|---|
| `ps aux` | Snapshot of all running processes |
| `top` | Live view of process activity, load average, CPU/memory breakdown |
| `systemctl status/enable --now <service>` | Check, start, and persist a background service across reboots |
| `journalctl -xe` | Recent system log with explanations |
| `crontab -e` | Edit a user's scheduled jobs (5-field time syntax: minute hour dom month dow) |

Verified a cron job end-to-end by writing a test line that appended a timestamped log entry every minute, and confirming it fired via `cat`.

### 3. Package Management

| Command | Purpose |
|---|---|
| `sudo apt update && sudo apt full-upgrade -y` | Refresh package index, then upgrade everything (allowing dependency-driven package changes) |
| `sudo apt install <pkg> -y` | Install a package non-interactively |
| `apt-cache search <term>` | Find packages by name/description keyword |
| `dpkg -l \| grep <pkg>` | List installed packages and confirm one is present |

### 4. Core Networking

| Command | Purpose |
|---|---|
| `ip a` | Show interfaces and assigned IP addresses |
| `ip route` | Show the routing table and default gateway |
| `nmcli device status` | NetworkManager's view of active connections |
| `ping -c 4 <host>` | Test basic reachability |
| `dig <domain>` | Resolve a domain name and inspect the DNS response |
| `ss -tulpn` | List listening TCP/UDP ports and the owning process |

Key concept: distinguishing services bound to `0.0.0.0` (reachable from the network) from those bound to `127.0.0.1` (loopback-only, no external exposure).

### 5. Diagnostics & Recon

| Command | Purpose |
|---|---|
| `nmap -sn <subnet>` | Host discovery — sweep a subnet for live hosts |
| `nmap -sV -p- <host>` | Full port scan (all 65,535 ports) with service/version fingerprinting |
| `sudo tcpdump -i <iface> -c 10` | Capture live packets on an interface |
| `nc -zv <host> <port>` | Test whether a specific port is reachable |

### 6. Firewalls & Remote Access

| Command | Purpose |
|---|---|
| `sudo ufw allow ssh` | Whitelist SSH *before* enabling the firewall (avoids locking out remote access) |
| `sudo ufw enable` | Switch to a default-deny-incoming policy |
| `sudo ufw status verbose` | Review active policy and rules |
| `ssh user@host` | Remote shell login |
| `ssh-keygen -t ed25519` | Generate a public/private key pair |
| `ssh-copy-id user@host` | Install a public key on a remote account's `authorized_keys` |
| `/etc/ssh/sshd_config` | Server-side SSH policy (root login, password auth) |
| `sudo apt install fail2ban -y` | Auto-ban IPs after repeated failed login attempts |

Verified key-based login by confirming `Accepted publickey` (rather than `Accepted password`) in the auth log after setup.

### 7. Logs & Monitoring

| Command | Purpose |
|---|---|
| `sudo tail -n 20 /var/log/auth.log` | Review recent authentication events (logins, sudo usage, SSH activity) |
| `df -h` | Disk space usage per filesystem |
| `free -h` | Memory usage (focus on the `available` column, not raw "used") |
| `uptime` | System uptime, active sessions, and load average |
| `journalctl -u <service> --no-pager \| tail -n 20` | Recent history for one specific systemd service |

### 8. Bonus: Shell Scripting & Integration

**`disk-check.sh`** — a small bash script that checks root filesystem usage against a threshold and prints a warning if it's exceeded (see [`disk-check.sh`](./disk-check.sh)). Debugged two real bugs during development: a corrupted shebang line and a typo'd variable name (`THSRESHOLD` vs `THRESHOLD`) that silently broke the threshold comparison — a good example of why reading a script's actual saved content (`cat`) beats guessing when something doesn't behave as expected.

**Integration exercise** — chained three tools together to observe a firewall rule take effect live:
1. `sudo ufw deny 8080` — explicitly block a port
2. `sudo journalctl -f` (second terminal) — follow the live system log
3. `sudo nmap -p 22,8080 <host>` — scan both ports, confirming 22 stayed `open` while 8080 flipped to `filtered`

## Notable Troubleshooting

- **VirtualBox Guest Additions install failed silently** when run directly (`./VBoxLinuxAdditions.run`) because the Guest Additions CD is mounted read-only via ISO9660 with `fmode=400` (no execute bit, even for root). Fixed by running it through the shell interpreter instead: `sudo bash VBoxLinuxAdditions.run`.
- **`sudo reboot` refused to run**, blocked by a systemd inhibitor protecting the active desktop session. Resolved with `sudo systemctl reboot -i` (`-i` ignores inhibitors).
- **A saved crontab initially failed to take effect** due to a stray character accidentally included at the top of the file during editing — resolved by deleting the bad line in `nano` before saving.

## Key Takeaways

- Most real-world Linux admin work is about reading output carefully (`ss`, `nmap`, log files) rather than memorizing commands.
- Almost every "it's not working" moment in this lab traced back to a typo or an ordering mistake (e.g., allowing SSH *before* enabling the firewall) — not a conceptual misunderstanding.
- The same toolset that's used to *observe* a system (`ps`, `ss`, `journalctl`) is also what's used to *prove* a change worked (before/after comparisons throughout this lab).

## Full documentation & screenshots

See [`Linux-Admin-Lab-Final-Documentation.docx`](./Linux-Admin-Lab-Final-Documentation.docx) for the complete write-up with embedded screenshots, and [`SS.zip`](./SS.zip) for the curated evidence screenshots referenced throughout.
