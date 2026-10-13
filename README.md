# borgmatic

[![CI](https://github.com/Arakmar/puppet-borgmatic/actions/workflows/ci.yml/badge.svg)](https://github.com/Arakmar/puppet-borgmatic/actions/workflows/ci.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/arakmar/borgmatic.svg)](https://forge.puppet.com/modules/arakmar/borgmatic)

## Table of contents

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
    * [Backup clients](#backup-clients)
    * [Options without a parameter](#options-without-a-parameter)
    * [Backup servers](#backup-servers)
    * [Exported resources](#exported-resources)
    * [Hiera](#hiera)
1. [Upgrading from the unversioned module](#upgrading-from-the-unversioned-module)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

This module manages [borgmatic](https://torsion.org/borgmatic/) on the hosts
being backed up and the [Borg](https://www.borgbackup.org/) repositories they
back up to on the backup servers.

On a backup client:

* class `borgmatic` installs borgmatic and manages its configuration
  directory;
* `borgmatic::config` writes a configuration file in the flat format of
  borgmatic 1.8 and later, with one typed parameter per borgmatic option,
  and has borgmatic validate it before replacing it;
* `borgmatic::timer` runs a configuration from a systemd timer.

On a backup server:

* class `borgmatic::server` installs Borg and manages the directory holding
  the repositories;
* `borgmatic::repository` creates a repository with `borg init`;
* `borgmatic::authorized_key` lets an SSH key run a restricted `borg serve`.

Clients can export their repositories and keys to their backup servers.

## Setup

### Requirements

* Puppet 8 or OpenVox 8, with PuppetDB to use exported resources.
* [puppetlabs/stdlib](https://forge.puppet.com/modules/puppetlabs/stdlib) 9.x
  or 10.x and [puppet/systemd](https://forge.puppet.com/modules/puppet/systemd)
  8.2 or later.
* On the clients, borgmatic 1.8 or later, the first release reading the flat
  configuration format, and systemd for `borgmatic::timer`. An option is only
  accepted by the borgmatic releases that know it, `commands` for instance
  needs borgmatic 2.0; the validation step reports the others. The packaged
  releases are:

  | Distribution          | borgmatic | Notes                                              |
  |-----------------------|-----------|----------------------------------------------------|
  | Debian 13             | 1.9.14    |                                                    |
  | Debian 12             | 1.7.7     | too old, install a newer one and set `binary_path` |
  | Ubuntu 24.04          | 1.8.3     | `only_run_on` in `checks` needs 1.8.13             |
  | Ubuntu 22.04          | 1.5.20    | too old, install a newer one and set `binary_path` |
  | EL 9 (EPEL)           | 1.8.13    |                                                    |
  | Fedora, Arch Linux    | 2.1       |                                                    |

* On the servers, Borg 1.x: repositories are created with `borg init`, Borg 2
  is still in beta.

The module is unit tested on EL 8 to 10 (RHEL, CentOS Stream, Rocky,
AlmaLinux), Debian 12 and 13, Ubuntu 22.04 and 24.04 and Arch Linux.

### Beginning with borgmatic

```puppet
include borgmatic

borgmatic::config { 'system':
  source_directories    => ['/etc', '/home', '/root', '/var'],
  repositories          => ['ssh://borg@backup.example.org/srv/borg/client1'],
  encryption_passphrase => Sensitive('correct horse battery staple'),
  keep_daily            => 7,
  keep_weekly           => 4,
}

borgmatic::timer { 'system':
  on_calendar => '*-*-* 01:00:00',
}
```

This writes `/etc/borgmatic.d/system.yaml` and runs it every night at 1 AM
from `borgmatic-system.timer`.

## Usage

### Backup clients

`borgmatic::config` has a parameter for each borgmatic option, named after
it; see the [borgmatic reference](https://torsion.org/borgmatic/reference/configuration/)
for their meaning and [REFERENCE.md](REFERENCE.md) for their types. Undef
options are left out of the file, so borgmatic applies its own defaults.

```puppet
borgmatic::config { 'system':
  source_directories    => ['/etc', '/home', '/root', '/var'],
  exclude_patterns      => ['/var/cache', '/var/tmp', '/home/*/.cache'],
  repositories          => [
    { 'path' => 'ssh://borg-client1@backup1.example.org/srv/borg/client1', 'label' => 'backup1' },
    { 'path' => 'ssh://borg-client1@backup2.example.org/srv/borg/client1', 'label' => 'backup2' },
  ],
  ssh_command           => 'ssh -i /root/.ssh/id_backup',
  encryption_passphrase => Sensitive('correct horse battery staple'),
  compression           => 'zstd,3',
  umask                 => '0027',
  keep_daily            => 7,
  keep_weekly           => 4,
  keep_monthly          => 6,
  checks                => [
    { 'name' => 'repository', 'frequency' => '2 weeks' },
    { 'name' => 'archives', 'frequency' => '1 month' },
  ],
  commands              => [
    { 'after' => 'error', 'run' => ['echo "Backup failed: {error}" | mail -s borgmatic root'] },
  ],
  healthchecks          => 'https://hc-ping.com/your-uuid-here',
}
```

A few conveniences on top of the borgmatic options:

* repositories and checks can be plain strings, written as `path` and `name`
  hashes;
* `umask` is an octal string such as `'0027'`, rendered as the integer
  borgmatic expects;
* `healthchecks` and `cronitor` accept the ping URL and `pagerduty` the
  integration key;
* when a value is `Sensitive`, such as the passphrase or a database password,
  the whole file content is, which keeps it out of reports and logs.

The file is checked with `borgmatic config validate` before it is replaced
(`validate => false` to skip it), so an option unknown to the installed
borgmatic fails the Puppet run instead of the next backup.

borgmatic 2.0 replaced the `before_backup`, `after_backup`, `on_error`... hooks
with `commands`. Both are available: the former are deprecated but are the
only ones borgmatic 1.9 understands.

Database dumps use the hook parameters of each database type:

```puppet
borgmatic::config { 'databases':
  repositories      => ['ssh://borg-client1@backup1.example.org/srv/borg/client1-db'],
  mariadb_databases => [
    { 'name' => 'all', 'username' => 'backup', 'password' => Sensitive('secret') },
  ],
  keep_hourly       => 24,
  keep_daily        => 7,
}

borgmatic::timer { 'databases':
  on_calendar => 'hourly',
}
```

`borgmatic::timer` runs `borgmatic --config <config_dir>/<title>.yaml`. It
can run a whole directory of configurations, pass logging flags and run
specific actions:

```puppet
borgmatic::timer { 'volumes':
  config             => '/etc/borgmatic.d/volumes',
  on_calendar        => ['*-*-* 02:15:00', '*-*-* 14:15:00'],
  verbosity          => -1,
  syslog_verbosity   => 1,
  log_file           => '/var/log/borgmatic/volumes.log',
  log_file_verbosity => 1,
}
```

Missed runs are caught up at boot (`persistent`), the service runs with a low
CPU and I/O priority, and `enable => false` keeps the units without starting
the timer, for runs triggered by hand or by another unit. Some packages ship a
`borgmatic.timer` running every configuration of `/etc/borgmatic.d`; set
`package_timer => false` on class `borgmatic` to stop it.

### Options without a parameter

`options` adds any borgmatic option, typically one newer than the module. It
is merged last and replaces the options of the same name:

```puppet
borgmatic::config { 'system':
  repositories => ['/srv/borg/system'],
  options      => {
    'bootstrap'        => { 'store_config_files' => false },
    'archive_hostname' => 'client1',
  },
}
```

### Backup servers

```puppet
class { 'borgmatic::server':
  base_path => '/srv/borg',
  group     => 'borgmatic',
  mode      => '0750',
}

borgmatic::repository { 'client1':
  owner           => 'borg-client1',
  passphrase      => Sensitive('correct horse battery staple'),
  umask           => '0027',
  authorized_keys => {
    'root' => { 'key' => 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... root@client1' },
  },
}
```

The repository is `/srv/borg/client1` (`path` to change it), owned by
`borg-client1`, which must exist, and initialised once with the
`repokey-blake2` encryption (`encryption` here or on `borgmatic::server`).
The passphrase must match the `encryption_passphrase` of the client. An
existing repository is never modified.

The key is added to `/home/borg-client1/.ssh/authorized_keys` with a forced
command:

```
command="/usr/bin/borg serve --restrict-to-path /srv/borg/client1 --umask 0027",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... root@client1
```

`borgmatic::authorized_key` declares such keys on its own, for instance an
append-only key for a monitoring user that can read the repository through its
group:

```puppet
borgmatic::authorized_key { 'client1_monitoring':
  user              => 'borg-client1-check',
  key               => 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... nagios@client1',
  restrict_to_paths => ['/srv/borg/client1'],
  append_only       => true,
}
```

### Exported resources

A client can export its repository and key to its backup servers, which
collect them:

```puppet
# On the client
$user = "borg-${facts['networking']['hostname']}"

$backup_servers.each |String $server| {
  @@borgmatic::repository { "${server}_${facts['networking']['fqdn']}":
    path            => "/srv/borg/${facts['networking']['fqdn']}",
    owner           => $user,
    passphrase      => $passphrase,
    authorized_keys => { 'root' => { 'key' => $root_public_key } },
    tag             => "borgmatic_${server}",
  }
}

borgmatic::config { 'system':
  repositories          => $backup_servers.map |$server| {
    { 'path' => "ssh://${user}@${server}/srv/borg/${facts['networking']['fqdn']}", 'label' => $server }
  },
  encryption_passphrase => $passphrase,
  # ...
}

# On the server
include borgmatic::server

Borgmatic::Repository <<| tag == "borgmatic_${facts['networking']['fqdn']}" |>> {
  umask => '0027',
}
Borgmatic::Authorized_key <<| tag == "borgmatic_${facts['networking']['fqdn']}" |>>
```

The users owning the repositories are up to you, for example exported
`user` or `accounts::user` resources. The passphrase of an exported
repository is stored in PuppetDB.

### Hiera

Class `borgmatic` and `borgmatic::server` declare resources from hashes:

```yaml
borgmatic::package_timer: false
borgmatic::purge_config_dir: true
borgmatic::configs:
  system:
    source_directories: ['/etc', '/home']
    repositories: ['ssh://borg@backup.example.org/srv/borg/client1']
    encryption_passcommand: 'cat /root/.borg-passphrase'
    keep_daily: 7
borgmatic::timers:
  system:
    on_calendar: '*-*-* 01:00:00'

borgmatic::server::repositories:
  client1:
    owner: 'borg-client1'
    encryption: 'none'
```

## Upgrading from the unversioned module

Version 1.0.0 is a rewrite and breaks every interface of the previous,
unversioned module. The generated configuration files need borgmatic 1.8 or
later.

| Before                                                                    | Now                                                                                  |
|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| `borgmatic` (`base_path`, `backup_user`, `backup_group`, `backup_permissions`) on the server | `borgmatic::server` (`base_path`, `owner`, `group`, `mode`); `base_path` defaults to `/srv/borg` |
| `borgmatic::client`                                                       | `borgmatic::config`                                                                  |
| `client`, `backup_user`, `backup_servers`                                 | `repositories`, built by the caller: `ssh://<user>@<server><base_path>/borgmatic_<client>` keeps the previous paths |
| `config_file_destination`, `config_file_name`                             | `path`, `<config_dir>/<title>.yaml` by default                                       |
| `database_type`, `databases`                                              | `mysql_databases`, `mariadb_databases`, `postgresql_databases`...                    |
| `borg_create_umask`, `borg_default_umask` (`'27'`)                        | `umask` (`'0027'`)                                                                   |
| `extra_borg_options_create`, `_prune`, `_check`                           | `extra_borg_options` (`{ 'create' => '...' }`)                                       |
| `numeric_owner`, `bsd_flags`, `remote_rate_limit`                         | `numeric_ids`, `flags`, `upload_rate_limit`                                          |
| `retention_prefix`, `consistency_prefix`                                  | removed, borgmatic matches the archives with `archive_name_format` or `match_archives` |
| `cronhub`, `borgmatic_source_directory`                                   | removed (`options` if needed)                                                        |
| `checks` undef rendered `disabled`                                        | `checks` undef lets borgmatic run its default checks, pass `['disabled']` to skip them |
| `compression` defaulted to `lz4`                                          | undef, Borg uses `lz4`                                                               |
| `borgmatic::repository` `repo`                                            | `path`, `<base_path>/<title>` by default                                             |
| `borgmatic::repository` `backup_user`, `backup_group`                     | `owner`, `group`                                                                     |
| `borgmatic::repository` `encryptions` (default `none`)                    | `encryption` (default `repokey-blake2`)                                              |
| `borgmatic::repository` `dir_permissions`, `files_permissions` applied recursively | `mode` of the directory and `umask` of `borg init` and `borg serve`         |
| `borgmatic::repository` `configure_ssh`, `ssh_file_path`, `ssh_public_key`, `ssh_command` | `authorized_keys`                                            |
| `borgmatic::ssh`                                                          | `borgmatic::authorized_key`                                                          |
| `borgmatic::cron`                                                         | `borgmatic::timer`                                                                   |

Existing repositories are left as they are: `borg init` only runs when
`<path>/config` is missing. The authorized_keys lines are matched on the key
type and body, so the lines written by `borgmatic::ssh` are replaced in place.
To keep the permissions of the previous version, set `mode => '0750'` and
`umask => '0027'` on the repositories.

## Limitations

* `borgmatic::repository` creates Borg 1.x repositories and never modifies
  nor deletes an existing one. The keyfile encryption modes are not offered:
  the key would stay on the server.
* An SSH key can only be authorized once per authorized_keys file, the lines
  being matched on the key. The directory of the file must exist.
* The command line of `borgmatic::timer` is not quoted: the configuration
  path, log file and extra arguments cannot contain spaces.
* The validation step needs borgmatic installed on the node: keep
  `manage_package` or install it before the configurations.

## Development

```
pdk validate
pdk test unit
pdk bundle exec rake strings:generate:reference
```

When borgmatic is installed, the unit tests also check the rendered files with
`borgmatic config validate`; point `BORGMATIC` at another executable to test
another release.

GitHub Actions run the static validations, RuboCop, a REFERENCE.md freshness
check and the unit tests on every pull request and push to `master`, and
validate the rendered files with borgmatic 1.8.13, 1.9.14 and the latest
release (`.github/workflows/ci.yml`, modelled on the
[Vox Pupuli](https://github.com/voxpupuli/gha-puppet) workflows).

Pushing a `v<version>` tag publishes the module to the Puppet Forge and
creates a GitHub release through the Vox Pupuli reusable release workflow
(`.github/workflows/release.yml`). The repository needs a `release`
environment and the `PUPPET_FORGE_USERNAME` and `PUPPET_FORGE_API_KEY`
secrets; bump `metadata.json` to the tagged version first.

This module is licensed under the GPL-3.0-or-later license, see
[LICENSE](LICENSE). It was started by Guilhem Gorget.
