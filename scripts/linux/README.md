# Linux Toolbox (shell scripts)

Linux-focused scripts intended for troubleshooting and information gathering on
machines I don’t own. Scripts are designed to be:

- **Read-only** (collecting information, not changing config)
- **Auditable** (plain shell scripts, no obfuscation)
- **Consistent** in where they write output

## Conventions

- Default working directory: **`$HOME/jb`**
- Report files are created under `$HOME/jb` unless:
  - You specify `--output`, or
  - You override `--dir` (where available)
- Scripts can be downloaded directly from GitHub using `curl` or `wget`.

--------------------------------------------------------------------------------------------------------

## linux-prep-toolbox.sh

Prepares a working directory for Linux toolbox scripts.

### Behavior

- Creates a working directory (default: `$HOME/jb`)
- Writes a `README.txt` into that directory with:
  - Purpose of the folder
  - Links to the GitHub repo and scripts
- Optionally downloads:
  - `linux-get-system-info.sh`
  - `linux-get-network-info.sh`

### Download

```bash
curl -fsSL \
  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/linux/linux-prep-toolbox.sh \
  -o linux-prep-toolbox.sh

chmod +x linux-prep-toolbox.sh
```

### Usage

- Basic (folder + README only):

```bash
./linux-prep-toolbox.sh
```

- Full prep (folder + README + download tools):

```bash
./linux-prep-toolbox.sh --download-tools
```

- Custom working directory:

```bash
./linux-prep-toolbox.sh --dir /tmp/jb --download-tools
```
-------------------------------------------------------------------------------------------------------------

## linux-get-system-info.sh

Collects general system information into a text report.

### What it collects

- OS and kernel info (uname, /etc/os-release / lsb_release)
- CPU info (lscpu or /proc/cpuinfo)
- Memory (free -h or /proc/meminfo)
- Disks and filesystems (lsblk, df -h)
- Uptime and last boot time

### Download

```bash
curl -fsSL \
  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/linux/linux-get-system-info.sh \
  -o linux-get-system-info.sh

chmod +x linux-get-system-info.sh
```

### Usage

- Default (writes under $HOME/jb):
> ./linux-get-system-info.sh

This will create a file such as:
> $HOME/jb/systeminfo-HOST-YYYYMMDD-HHMMSS.txt

- Explicit output path:

```bash
./linux-get-system-info.sh --output /tmp/systeminfo.txt
```

- Custom working directory:

```bash
./linux-get-system-info.sh --dir /tmp/jb
```

> Note: If --output is provided, it takes precedence over --dir.

------------------------------------------------------------------------------------------

## linux-get-network-info.sh

Collects network-related information into a text report.

### What it collects

- Interfaces and addresses (ip addr or ifconfig -a)
- Routing table (ip route or netstat -rn)
- DNS configuration (/etc/resolv.conf)
- Hosts file (/etc/hosts)
- Listening sockets (ss -tulnp or netstat -tulnp)
- Connectivity tests to configurable targets (default: 1.1.1.1, 8.8.8.8, github.com)

### Download

```bash
curl -fsSL \
  https://raw.githubusercontent.com/JBOrunon/toolbox/main/scripts/linux/linux-get-network-info.sh \
  -o linux-get-network-info.sh

chmod +x linux-get-network-info.sh
```

### Usage

- Default (writes under $HOME/jb):
> ./linux-get-network-info.sh

This will create a file such as:
> $HOME/jb/networkinfo-HOST-YYYYMMDD-HHMMSS.txt

- Explicit output path:

```bash
./linux-get-network-info.sh --output /tmp/networkinfo.txt
```

- Custom working directory:
```bash
./linux-get-network-info.sh --dir /tmp/jb
```

- Custom connectivity targets:

```bash
./linux-get-network-info.sh --targets "8.8.8.8,1.1.1.1,github.com"
```

--------------------------------------------------------------------------------------------------------------
