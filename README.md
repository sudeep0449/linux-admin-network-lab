# Linux System & Network Administration Lab

I wanted real hands-on practice with the kind of Linux admin and networking work I'd actually be doing on the job, not just reading about the commands. So I set up my own Ubuntu VM and worked through users and permissions, services, networking, security, and logging end to end — every command below was actually run on a live system, and where something didn't work on the first try, I've left the troubleshooting notes in rather than cleaning them out. That's usually where I actually learned something.

## Environment

- **OS:** Ubuntu 26.04 LTS Desktop
- **Hypervisor:** VirtualBox (Windows host)
- **Networking:** VirtualBox NAT network (`10.0.2.0/24`)
- VirtualBox Guest Additions installed for host/guest clipboard integration

I'm not covering the VM setup or the Ubuntu install itself — that's just clicking through a standard installer. This starts once I actually began administering the system.

## What I covered

### 1. Filesystem, Permissions & Users

First stop was the layer everything else sits on: who owns a file, who's allowed to touch it, and how user accounts and group membership actually work.

| Command | What it does |
|---|---|
| `ls -la` | List files with permissions, ownership, and hidden files |
| `chmod 700 <dir>` | Lock a directory to owner-only access (octal: read=4, write=2, execute=1) |
| `useradd -m <user>` | Create a new user with a home directory |
| `passwd <user>` | Set/change a user's password |
| `usermod -aG sudo <user>` | Add a user to sudo without wiping their other group memberships |

Also spent time in `/etc/passwd` and `/etc/group` reading the field structure, and made sure I actually had straight the difference between `sudo <cmd>` (elevates just that one command) and a full root shell.

### 2. Processes & Services

Next was figuring out what's actually running at any given moment, managing background services properly, and getting something to run on its own schedule.

| Command | What it does |
|---|---|
| `ps aux` | Snapshot of all running processes |
| `top` | Live view of process activity, load average, CPU/memory |
| `systemctl status/enable --now <service>` | Check, start, and persist a service across reboots |
| `journalctl -xe` | Recent system log with explanations |
| `crontab -e` | Edit scheduled jobs (5-field syntax: minute hour dom month dow) |

I didn't just want to trust a cron job was scheduled right — I set up a test line that appended a timestamped entry to a log every minute and actually watched it fire.

### 3. Package Management

| Command | What it does |
|---|---|
| `sudo apt update && sudo apt full-upgrade -y` | Refresh the index, then upgrade everything non-interactively |
| `sudo apt install <pkg> -y` | Install a package without the confirmation prompt |
| `apt-cache search <term>` | Find packages by keyword |
| `dpkg -l \| grep <pkg>` | Confirm a specific package is installed |

### 4. Core Networking

| Command | What it does |
|---|---|
| `ip a` | Show interfaces and assigned IP addresses |
| `ip route` | Show the routing table and default gateway |
| `nmcli device status` | NetworkManager's view of active connections |
| `ping -c 4 <host>` | Test basic reachability |
| `dig <domain>` | Resolve a domain and inspect the DNS response |
| `ss -tulpn` | List listening TCP/UDP ports and the owning process |

The concept that really stuck with me: a service on `0.0.0.0` is reachable from the network, one on `127.0.0.1` only from itself. That mattered a lot once I got to the firewall.

### 5. Diagnostics & Recon

Up to here I'd mostly been looking at my own machine. This flips it around — probing the network itself.

| Command | What it does |
|---|---|
| `nmap -sn <subnet>` | Sweep a subnet to find live hosts |
| `nmap -sV -p- <host>` | Full port scan (all 65,535) with service/version fingerprinting |
| `sudo tcpdump -i <iface> -c 10` | Capture live packets on an interface |
| `nc -zv <host> <port>` | Test whether a specific port is reachable |

### 6. Firewalls & Remote Access

This was the section I was most careful with — get the order wrong here and you can lock yourself out of your own machine.

| Command | What it does |
|---|---|
| `sudo ufw allow ssh` | Whitelist SSH *before* enabling the firewall |
| `sudo ufw enable` | Switch to default-deny-incoming |
| `sudo ufw status verbose` | Review active policy and rules |
| `ssh user@host` | Remote shell login |
| `ssh-keygen -t ed25519` | Generate a key pair |
| `ssh-copy-id user@host` | Install a public key on a remote account |
| `/etc/ssh/sshd_config` | Server-side SSH policy |
| `sudo apt install fail2ban -y` | Auto-ban IPs after repeated failed logins |

I allowed SSH before turning the firewall on, not after. Then set up key-based auth and checked it two ways: a login with no password prompt, and then `Accepted publickey` (not `Accepted password`) in the auth log afterward.

### 7. Logs & Monitoring

| Command | What it does |
|---|---|
| `sudo tail -n 20 /var/log/auth.log` | Recent authentication events |
| `df -h` | Disk space per filesystem |
| `free -h` | Memory usage (the `available` column, not raw "used") |
| `uptime` | Uptime, sessions, load average |
| `journalctl -u <service> --no-pager \| tail -n 20` | Recent history for one service |

### 8. Bonus: Shell Scripting & Integration

**`disk-check.sh`** — a small script checking root filesystem usage against a threshold (see [`disk-check.sh`](./disk-check.sh)). Debugging it taught me more than writing it did: a stray character had glued itself onto the shebang line, and I'd misspelled the threshold variable on assignment (`THSRESHOLD` vs `THRESHOLD`), so it never actually got set — the comparison further down silently checked against nothing. Only caught it by `cat`-ing the actual saved file instead of assuming what I'd typed was what landed on disk.

**Integration exercise** — wanted to actually see a firewall rule take effect, not just trust it did, so I ran three tools together:
1. `sudo ufw deny 8080` — block a port
2. `sudo journalctl -f` (second terminal) — tail the live log
3. `sudo nmap -p 22,8080 <host>` — watch 22 stay `open` while 8080 flips to `filtered`

## Things that went wrong (and how I fixed them)

- **VirtualBox Guest Additions wouldn't run directly** (`./VBoxLinuxAdditions.run`) — its installer CD mounts read-only via ISO9660 with the execute bit stripped, even for root. Fixed with `sudo bash VBoxLinuxAdditions.run`.
- **`sudo reboot` refused to run**, blocked by a systemd inhibitor protecting my active desktop session. `sudo systemctl reboot -i` (`-i` ignores inhibitors) sorted it.
- **A saved crontab had no effect at first** — a stray character had snuck onto the top of the file while editing. Deleted it in `nano` and it started working.

## What I took away from this

- Most of what I actually did wasn't memorizing commands — it was reading output carefully, whether that's `ss`, `nmap`, or a log file.
- Nearly every "why isn't this working" moment came down to a typo or the wrong order (allowing SSH before enabling the firewall being the clearest case), not a real gap in understanding.
- The same tools I used to check on the system (`ps`, `ss`, `journalctl`) were also what proved a change had actually worked, just by comparing before and after.

## Full write-up & screenshots

[`Linux-Admin-Lab-Final-Documentation.docx`](./Linux-Admin-Lab-Final-Documentation.docx) has the complete write-up with embedded screenshots, and [`SS.zip`](./SS.zip) has the evidence screenshots referenced throughout.
