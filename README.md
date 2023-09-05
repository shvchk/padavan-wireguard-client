<p align="right">English | <a href="README.ru.md">Русский</a></p>


## WireGuard client for routers with Padavan based firmware

Single executable file only requiring standard WireGuard config file to work.

### Prerequisites

1. Firmware with WireGuard support.  
    E.g. [padavan-ng from Alexey](https://gitlab.com/dm38/padavan-ng), on your router up and running.

1. Ability to run commands on your router.  
    Preferably via SSH, but you could also use router web UI.

    <details>
      <summary>More info</summary>

      Enable SSH access in router's web UI: **Administration** → **Services** → **Enable SSH Server?** → **Yes**

      SSH connection credentials are the same that you use for web UI.

      Linux, Mac OS and Windows 10+ usually have SSH client preinstalled, just launch terminal and connect:

      ```sh
      ssh admin@192.168.1.1
      ```

      On older Windows versions you could use [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty), [Tabby](https://tabby.sh) or [other SSH clients](https://alternativeto.net/software/putty/?feature=ssh-client&license=free&platform=windows).

      When you have SSH client installed, you can often connect just by following this link:

      ```text
      ssh://admin@192.168.1.1
      ```

      Paste it into your browser's address bar manually and hit Enter, since GitHub doees not allow active links with non-standard protocols.
    </details>

1. Ability to copy files to your router.  
    SFTP is usually used for this, which is based on SSH.

    <details>
      <summary>More info</summary>

      On Windows you could use [WinSCP](https://winscp.net), for Mac OS there is [Cyberduck](https://cyberduck.io). Linux file managers usually support SFTP out of the box, look for "Network" or "Other places" section.

      You can connect just by following this link:

      ```text
      sftp://admin@192.168.1.1/etc/storage/
      ```

      Paste it into your browser's address bar manually and hit Enter, since GitHub doees not allow active links with non-standard protocols.
    </details>

### WireGuard client set up

I will mostly use CLI commands here to remove risk of misinterpretation, but file / directory operations might be as well performed via SFTP, or course.

1. If you have previous version of this WireGuard client installed (the one that consisted of several `.sh` files), you need to disable / remove it. Let's rename its directory for now without deleting anything:

    ```sh
    mv /etc/storage/wireguard /etc/storage/wireguard.bak
    ```

1. Create `wireguard` directory in `/etc/storage`:

    ```sh
    mkdir /etc/storage/wireguard
    ```

1. Copy `client.sh` to it:

    ```sh
    wget https://github.com/shvchk/padavan-wireguard-client/raw/main/client.sh -O /etc/storage/wireguard/client.sh
    ```

1. Make it executable:

    ```sh
    chmod +x /etc/storage/wireguard/client.sh
    ```

1. Copy WireGuard client config file to `/etc/storage/wireguard`

    Config file name will be used as a WireGuard interface name. E.g. for `wg0.conf` client create `wg0` interface.

    > [!IMPORTANT]  
    > File name should only consist of letters, numbers and `_` `=` `+` `.` `-` characters, be less than 16 characters long and end with `.conf`. If directory has multiple config files, first one in alphabetic order will be used.

1. Start WireGuard client:

    ```sh
    /etc/storage/wireguard/client.sh start
    ```

1. Check if internet is working fine on your devices:

    ```sh
    ping -c 3 -W 1 1.1.1.1
    ```

1. In case of problems, stop WireGuard client:

    ```sh
    /etc/storage/wireguard/client.sh stop
    ```

1. After you made sure everything is working fine, enable autostart:

    ```sh
    /etc/storage/wireguard/client.sh autostart enable
    ```

1. Save changes:

    ```sh
    mtd_storage.sh save
    ```

1. Restart router


### Uninstall

```sh
/etc/storage/wireguard/client.sh stop
/etc/storage/wireguard/client.sh autostart disable
rm -rf /etc/storage/wireguard
mtd_storage.sh save
```


### Add exceptions

You can add exceptions in one of these files:

- `/etc/storage/started_script.sh` (web UI: **Customization** → **Scripts** → **Run After Router Started**)

- `/etc/storage/post_iptables_script.sh` (web UI: **Customization** → **Scripts** → **Run After Firewall Rules Restarted**)

First add a tiny helper function:

```sh
direct() {
  ip rule del $1 $2 || :
  ip rule add $1 $2 table main pref 30
}
```

You can then use it like this: `direct <to|from> <IP-address|subnet>`. Examples:

- Route traffic **to** IP 9.9.9.9 directly: `direct to 9.9.9.9`

- Route traffic **to** subnet 1.2.0.0/16 directly: `direct to 1.2.0.0/16`

- Route traffic **from** IP 192.168.1.11 directly: `direct from 192.168.1.11`

- Route traffic **from** subnet 10.11.12.0/24 directly: `direct to 10.11.12.0/24`

You can add as many of these rules as you like, one per line.

If you changed files via SSH, don't forget to save changes:

```sh
mtd_storage.sh save
```
