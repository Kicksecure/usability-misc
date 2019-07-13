# Misc usability improvements #

Creates user "user" if it does not already exist.

Creates folders /home/user/Downloads and /home/user/Pictures.

Adds user "user" to group libvirt as well as to group kvm.

Ships a file /etc/sudoers.d/user-passwordless that contains comments and
"#user   ALL=(ALL:ALL) NOPASSWD:ALL". Lets user "user" easily run all
commands without password. Disabled (out commented) by default.

Simplifies running OpenVPN as unprivileged user.

Ships a FoxyProxy add-on configuration file for use with Tor Browser.

Process configuration folder /etc/audit/rules.d/ by default if auditd is
installed.

Provides apt-get-noninteractive that is a simple wrapper around apt-get, that
sets all required environment variables to make it interactive as well as to
prevent systemd service starts and restarts during apt-get.

Sets mousepad as the default editor for sudoedit if environment variable
SUDO_EDITOR is unset and if mousepad is installed.
## How to install `usability-misc` using apt-get ##

1\. Add [Whonix's Signing Key](https://www.whonix.org/wiki/Whonix_Signing_Key).

```
sudo apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg adv --keyserver hkp://ipv4.pool.sks-keyservers.net:80 --recv-keys 916B8D99C38EAF5E8ADC7A2A8D66066A2EEACCDA
```

3\. Add Whonix's APT repository.

```
echo "deb http://deb.whonix.org buster main contrib non-free" | sudo tee /etc/apt/sources.list.d/whonix.list
```

4\. Update your package lists.

```
sudo apt-get update
```

5\. Install `usability-misc`.

```
sudo apt-get install usability-misc
```

## How to Build deb Package ##

Replace `apparmor-profile-torbrowser` with the actual name of this package with `usability-misc` and see [instructions](https://www.whonix.org/wiki/Dev/Build_Documentation/apparmor-profile-torbrowser).

## Contact ##

* [Free Forum Support](https://forums.whonix.org)
* [Professional Support](https://www.whonix.org/wiki/Professional_Support)

## Donate ##

`usability-misc` requires [donations](https://www.whonix.org/wiki/Donate) to stay alive!
