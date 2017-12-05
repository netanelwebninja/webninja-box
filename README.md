# WEBNinja Box

**Vagrant box packed with all the goodies for modern web development.**

## Getting started using vagrant cloud

webninja/box is available on Vagrant Cloud, so its very simple to start using it.

```sh
$ vagrant init webninja/box
$ vagrant up
```

## Getting started manually
#### Create folder and Vagrantfile:
```sh
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

    config.vm.box = "webninja/box"
    config.vm.box_version = "1.0"
    
    config.vm.hostname = "webninjabox"
    config.vm.network "forwarded_port", guest: 80, host: 8080
    config.vm.network "private_network", ip: "192.168.33.10"
    
    config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=666"]

end
```

#### Execute on cli
```sh
$ vagrant up
```

### Goodied Pre Packed for You
**Based on Ubuntu 16.04.1**
| Plugin | Version | Info |
| ------ | ------ | ------ |
| OS Packages | latest | `build-essential tcl curl fail2ban gcc git vim libmcrypt4 libpcre3-dev make python2.7 python-pip sendmail supervisor ufw unattended-upgrades unzip whois zsh` |
| PHP | 7.2.0 | **Packages:** `php7.2-cli php7.2-dev php7.2-fpm php7.2-pgsql php7.2-sqlite3 php7.2-gd php7.2-curl php7.2-memcached php7.2-imap php7.2-mysql php7.2-mbstring php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap php7.2-intl php7.2-readline` |
| Composer | 1.5.5 | Installed globallay
| Nginx | latest | **Root path:** `/var/www/public`
| MySQL | 5.7.20 | **Username:** `root` **Password:** `root` **Database:** `webninja`
| PostgreSQL | 9.5.10 | **Username:** `root` **Password:** `root` **Database:** `webninja`
| Sqlite | latest |
| Redis | 4.0.6 | **Hostname:** `localhost` **Port:** `6379`
| Memcahed | latest |
| Supervisor | latest |
| Beanstalkd | latest |
| Ruby | 2.4.1 (rvm) |
| Node.js | 6.10.3 (nvm) | **Global packages:** `gulp, grunt, bower, yo, browser-sync, browserify, pm2, webpack` **Also `yarn` alonside npm**
| Laravel installer | latest | Use `laravel new project` for crafting new laravel project 
| ngrok client | latest |
