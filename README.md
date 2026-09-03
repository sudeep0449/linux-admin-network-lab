# Linux System & Network Administration Lab

This project was built to gain practical, hands-on experience with core Linux system and network administration tasks rather than studying them in the abstract. I provisioned my own Ubuntu virtual machine and worked through user and permission management, service administration, package management, networking, security hardening, and log analysis, executing every command directly. Where issues arose during the process, the troubleshooting steps are documented alongside the resolution, since diagnosing and resolving real problems was a core part of the exercise. All 24 evidence screenshots referenced below are included in [`Screenshots.zip`](./Screenshots.zip), numbered in the order they occurred within each section.
## Environment

- **OS:** Ubuntu 26.04 LTS Desktop
- **Hypervisor:** VirtualBox (Windows host)
- **Networking:** VirtualBox NAT network (`10.0.2.0/24`)
- VirtualBox Guest Additions installed for host/guest clipboard integration

Initial VM provisioning and the Ubuntu installation itself are not covered here, as they follow the standard installation process. This write-up begins at the point where hands-on administration work started.

## 1. Filesystem, Permissions & Users

This section covers the foundational layer that everything else depends on: file ownership, access control, and how user accounts and group membership are structured.

| Command | Purpose |
|---|---|
| `ls -la` | List files with permissions, ownership, and hidden files |
| `chmod 700 <dir>` | Restrict a directory to owner-only access (octal: read=4, write=2, execute=1) |
| `useradd -m <user>` | Create a new user with a home directory |
| `passwd <user>` | Set or change a user's password |
| `usermod -aG sudo <user>` | Add a user to sudo, appending rather than overwriting existing group memberships |

Also reviewed the field structure of `/etc/passwd` and `/etc/group`, and confirmed the distinction between `sudo <cmd>` (elevates a single command) and a persistent root shell.

| # | Screenshot | What's happening |
|---|---|---|
| 01 | `01-filesystem-permissions-chmod-verified.png` | `chmod 700 ~/Documents`, verified with `ls -la` showing `drwx------` — owner-only access confirmed |
| 02 | `01-filesystem-permissions-user-group-sudo.png` | `usermod -aG sudo alex` required re-entering the sudo password once after an initial authentication failure; `id alex` and `grep sudo /etc/group` then confirmed alex was added to group 27 (`sudo`), with `/bin/sh` as the default shell per `/etc/passwd` |

## 2. Processes & Services

This section covers process visibility, service management, and task scheduling.

| Command | Purpose |
|---|---|
| `ps aux` | Snapshot of all running processes |
| `top` | Live view of process activity, load average, CPU/memory |
| `systemctl status/enable --now <service>` | Check, start, and persist a service across reboots |
| `journalctl -xe` | Recent system log with explanations |
| `crontab -e` | Edit scheduled jobs (5-field syntax: minute hour dom month dow) |

A cron job was verified end-to-end: a test line was configured to append a timestamped entry to a log file every minute, with the output confirmed directly.

| # | Screenshot | What's happening |
|---|---|---|
| 03 | `02-processes-services-ssh-active.png` | `systemctl status ssh` right after `enable --now` — service active and listening on port 22 |
| 04 | `02-processes-cron-crontab-l-verified.png` | `crontab -l` confirming the final, correctly saved cron job line |
| 05 | `02-processes-cron-test-log-fired.png` | `cat` on the test log — two timestamped entries one minute apart, proving the job fired on its own |

## 3. Package Management

Ubuntu's package management is structured in two layers: `apt` for day-to-day installing/updating/searching, and `dpkg` underneath it for inspecting what's already installed.

| Command | Purpose |
|---|---|
| `sudo apt update && sudo apt full-upgrade -y` | Refresh the index, then upgrade everything non-interactively |
| `sudo apt install <pkg> -y` | Install a package without the confirmation prompt |
| `apt-cache search <term>` | Find packages by keyword |
| `dpkg -l \| grep <pkg>` | Confirm a specific package is installed |

| # | Screenshot | What's happening |
|---|---|---|
| 06 | `03-package-management-tree-install.png` | Installed `tree` and used it to print the home directory as a visual tree, Snap's versioned package layout included |
| 07 | `03-package-management-dpkg-verified.png` | `dpkg -l` piped through `grep`, confirming `tree` is installed along with its version |

## 4. Core Networking

This section covers addressing, routing, and name resolution — the fundamentals of how the machine communicates on a network.

| Command | Purpose |
|---|---|
| `ip a` | Show interfaces and assigned IP addresses |
| `ip route` | Show the routing table and default gateway |
| `nmcli device status` | NetworkManager's view of active connections |
| `ping -c 4 <host>` | Test basic reachability |
| `dig <domain>` | Resolve a domain and inspect the DNS response |
| `ss -tulpn` | List listening TCP/UDP ports and the owning process |

Key distinction established here: a service on `0.0.0.0` is reachable from the network, one on `127.0.0.1` only from processes on the same machine — directly relevant to the firewall section below.

| # | Screenshot | What's happening |
|---|---|---|
| 08 | `04-networking-ip-a-interface.png` | `ip a` showing the `enp0s3` interface and its address on the VirtualBox NAT network |
| 09 | `04-networking-ping-8888.png` | `ping -c 4 8.8.8.8` completing with 0% packet loss — outbound connectivity confirmed |
| 10 | `04-networking-dig-google.png` | `dig google.com`, with the ANSWER SECTION showing the resolved A record |
| 11 | `04-networking-ss-tulpn-sudo.png` | `sudo ss -tulpn` showing listening ports with full process names (`sshd`, `cupsd`, `systemd-resolve`) |

## 5. Diagnostics & Recon

This section shifts from reviewing local configuration to actively probing the network: discovering live hosts, scanning for open ports, and capturing traffic.

| Command | Purpose |
|---|---|
| `nmap -sn <subnet>` | Sweep a subnet to identify live hosts |
| `nmap -sV -p- <host>` | Full port scan (all 65,535) with service/version fingerprinting |
| `sudo tcpdump -i <iface> -c 10` | Capture live packets on an interface |
| `nc -zv <host> <port>` | Test whether a specific port is reachable |

| # | Screenshot | What's happening |
|---|---|---|
| 12 | `05-diagnostics-nmap-host-discovery.png` | `sudo nmap -sn` across the NAT subnet — identified the gateway, the DHCP helper, and the VM itself |
| 13 | `05-diagnostics-nmap-port-scan-ssh.png` | Full 65,535-port scan completing with only port 22 open, correctly fingerprinted as OpenSSH |
| 14 | `05-diagnostics-tcpdump-capture.png` | `tcpdump` capturing live NTP, DNS, and ARP traffic on the primary interface |

## 6. Firewalls & Remote Access

This section required particular care: an incorrect order of operations here can result in losing remote access to the machine entirely.

| Command | Purpose |
|---|---|
| `sudo ufw allow ssh` | Whitelist SSH *before* enabling the firewall |
| `sudo ufw enable` | Switch to a default-deny-incoming policy |
| `sudo ufw status verbose` | Review active policy and rules |
| `ssh user@host` | Remote shell login |
| `ssh-keygen -t ed25519` | Generate a public/private key pair |
| `ssh-copy-id user@host` | Install a public key on a remote account's `authorized_keys` |
| `/etc/ssh/sshd_config` | Server-side SSH policy |
| `sudo apt install fail2ban -y` | Auto-ban IPs after repeated failed login attempts |

SSH was explicitly allowed before enabling the firewall. Key-based authentication was then configured and verified two ways: a login requiring no password prompt, and confirmation in the auth log showing `Accepted publickey` rather than `Accepted password`.

| # | Screenshot | What's happening |
|---|---|---|
| 15 | `06-firewall-ufw-enabled-sessions.png` | `ufw allow ssh`, `enable`, and `status verbose` — firewall active with only port 22 allowed; `loginctl list-sessions` distinguishing the console login from the SSH session |
| 16 | `06-firewall-ssh-login-fingerprint.png` | First SSH login: host key fingerprint verification, then a successful login and the Ubuntu welcome banner |
| 17 | `06-firewall-ssh-keygen-ed25519.png` | `ssh-keygen -t ed25519` generating a new key pair, including its randomart fingerprint |
| 18 | `06-firewall-ssh-copy-id-passwordless.png` | `ssh-copy-id` installing the public key, immediately followed by an SSH login with no password prompt |
| 19 | `06-firewall-fail2ban-active.png` | `fail2ban` installed and running, actively watching the authentication logs |

## 7. Logs & Monitoring

This section covers reviewing the historical record of system activity: authentication events, resource usage, and logs scoped to a single service.

| Command | Purpose |
|---|---|
| `sudo tail -n 20 /var/log/auth.log` | Review recent authentication events |
| `df -h` | Disk space usage per filesystem |
| `free -h` | Memory usage (the `available` column, not raw "used") |
| `uptime` | System uptime, active sessions, and load average |
| `journalctl -u <service> --no-pager \| tail -n 20` | Recent history for one specific service |

| # | Screenshot | What's happening |
|---|---|---|
| 20 | `07-logs-auth-log-password-publickey.png` | `tail -n 20` on the auth log — a password login and a publickey login both recorded, side by side |
| 21 | `07-logs-journalctl-ssh-history.png` | `journalctl -u ssh` — earlier failed password attempts, then a later accepted publickey login |

## 8. Bonus: Shell Scripting & Integration

This closing section covers writing and debugging a small bash script, and chaining tools together to observe a firewall rule take effect in real time.

**`disk-check.sh`** ([source](./disk-check.sh)) checks root filesystem usage against a configurable threshold and prints a warning if exceeded:

```bash
#!/bin/bash

THRESHOLD=80
USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$USAGE" -ge "$THRESHOLD" ]; then
    echo "WARNING: Disk usage is at ${USAGE}% — above the ${THRESHOLD}% threshold!"
else
    echo "OK: Disk usage is at ${USAGE}% — within normal range."
fi
```

Debugging the script proved more instructive than writing it. Two issues were identified: a stray character had been introduced at the start of the shebang line, and the threshold variable had been misspelled on assignment (`THSRESHOLD` vs `THRESHOLD`), meaning it was never actually set — the comparison further down silently evaluated against an empty value. This was diagnosed by reviewing the script's actual saved contents with `cat` rather than assuming the intended text had been entered correctly.

**Integration exercise** — to directly observe a firewall change take effect, three tools were used together:
1. `sudo ufw deny 8080` — explicitly block a port
2. `sudo journalctl -f` (second terminal) — follow the live system log
3. `sudo nmap -p 22,8080 <host>` — confirm 22 remained `open` while 8080 changed to `filtered`

| # | Screenshot | What's happening |
|---|---|---|
| 22 | `08-bonus-script-bugs-and-fix.png` | `cat disk-check.sh` revealing both bugs, followed by the corrected version after fixing the shebang and the variable name |
| 23 | `08-bonus-script-ok-warning-final-nmap.png` | The corrected script producing a genuine OK result, then — with the threshold temporarily lowered — a genuine WARNING result |
| 24 | `08-bonus-ufw-deny-journalctl-live.png` | `ufw deny 8080` alongside `journalctl -f` — the live, timestamped audit trail of both the rule change and the nmap scan |

## Notable Troubleshooting

- **VirtualBox Guest Additions failed to run directly** (`./VBoxLinuxAdditions.run`) — its installer CD mounts read-only via ISO9660 with the execute permission removed, even for root. Resolved with `sudo bash VBoxLinuxAdditions.run`.
- **`sudo reboot` was blocked** by a systemd inhibitor protecting the active desktop session. Resolved with `sudo systemctl reboot -i` (`-i` ignores inhibitors).
- **A saved crontab initially had no effect** due to a stray character introduced at the top of the file during editing. Resolved by removing the line in `nano`.

## Key Takeaways

- Most of the practical work involved careful interpretation of command output — `ss`, `nmap`, and log files — rather than memorization of syntax.
- The majority of issues encountered were the result of typographical errors or incorrect sequencing (such as enabling the firewall before allowing SSH), rather than gaps in conceptual understanding.
- The same tools used to inspect system state (`ps`, `ss`, `journalctl`) were also used to verify that configuration changes had taken effect, through direct before-and-after comparison.

## Full Documentation

[`Linux-Admin-Lab-Final-Documentation.pdf`](./Linux-Admin-Lab-Final-Documentation.pdf) contains this same write-up as a formatted report with every screenshot embedded inline.
