# Changelog

All notable changes to this project will be documented in this file.

## Release 1.0.0

First versioned release, published as `arakmar-borgmatic`. The module
previously lived on an unversioned master branch; this release rewrites it
for Puppet 8 and the configuration format of borgmatic 1.8 and later. See
the upgrade table of the README.

**Breaking changes**

* Puppet 8 (or OpenVox 8), puppetlabs/stdlib 9.x or 10.x and
  puppet/systemd >= 8.2.0 are required. npwalker/recursive_file_permissions
  is no longer used.
* The generated configuration files use the flat format of borgmatic 1.8 and
  later instead of the location, storage, retention, consistency and hooks
  sections, repositories and checks are written as hashes and the
  healthchecks, cronitor and pagerduty hooks as hashes, which removes every
  deprecation warning of borgmatic 1.8 to 2.1. Older borgmatic releases
  cannot read them.
* `borgmatic::client` is replaced by `borgmatic::config`, whose parameters
  are named and typed after the borgmatic options. `repositories` replaces
  `client`, `backup_user` and `backup_servers`; `path` replaces
  `config_file_destination` and `config_file_name`; one parameter per
  database type replaces `database_type` and `databases`; `umask` (an octal
  string) replaces `borg_create_umask` and `borg_default_umask`;
  `extra_borg_options` replaces `extra_borg_options_create`, `_prune` and
  `_check`; `numeric_ids`, `flags` and `upload_rate_limit` replace
  `numeric_owner`, `bsd_flags` and `remote_rate_limit`. `retention_prefix`,
  `consistency_prefix`, `borgmatic_source_directory` and `cronhub` are
  removed. `compression` no longer defaults to `lz4` and an undef `checks`
  no longer renders `disabled`: Borg and borgmatic defaults apply.
* The server side moved from class `borgmatic` to `borgmatic::server`, which
  installs Borg instead of borgmatic. `base_path` defaults to `/srv/borg`
  instead of `/mnt/backup`; `backup_user`, `backup_group` and
  `backup_permissions` are renamed `owner`, `group` and `mode`. Class
  `borgmatic::config` is removed.
* `borgmatic::repository` takes the repository `path` (`<base_path>/<title>`
  by default) instead of `repo`, which the `borgmatic_` prefix was added
  to. `backup_user` and `backup_group` are renamed `owner` and `group`,
  `encryptions` is renamed `encryption` and defaults to `repokey-blake2`
  instead of `none`, the keyfile modes are refused. `dir_permissions` and
  `files_permissions`, applied recursively, give way to the `mode` of the
  repository directory and the `umask` of Borg. `configure_ssh`,
  `ssh_file_path`, `ssh_public_key` and `ssh_command` give way to
  `authorized_keys`.
* `borgmatic::ssh` is replaced by `borgmatic::authorized_key`, which builds
  the `borg serve` command from its restrictions.
* `borgmatic::cron` is replaced by `borgmatic::timer`.

**Features**

* `borgmatic::config` covers the options of borgmatic 2.1: among others
  `commands`, `constants`, `working_directory`, `borg_exit_codes`,
  `match_archives`, `keep_13weekly`, `keep_3monthly`, `compact_threshold`,
  `retries`, the logging options, `skip_actions`, the PostgreSQL, MariaDB,
  MySQL, SQLite and MongoDB database hooks, the ntfy, Pushover, Zabbix,
  Apprise, Healthchecks, Uptime Kuma, Cronitor, PagerDuty, Loki and Sentry
  monitoring hooks and the ZFS, Btrfs and LVM snapshot hooks. `options` sets
  any other option.
* `borgmatic::config` validates the file with `borgmatic config validate`
  before replacing it and makes its content Sensitive when a value is.
* `borgmatic::timer` runs a configuration from a persistent systemd timer
  with a low CPU and I/O priority.
* Class `borgmatic` manages the configuration directory, optionally purged,
  can stop the `borgmatic.timer` unit of the package and declares
  configurations and timers from Hiera hashes; `borgmatic::server` does the
  same for repositories and authorized keys.
* `borgmatic::repository` passes `umask`, `append_only` and `storage_quota`
  to `borg init` and accepts a Sensitive passphrase.
* `borgmatic::authorized_key` supports several paths, repository
  restrictions, append-only access, a umask, a storage quota and extra
  options.
* Type aliases, puppet-strings documentation (REFERENCE.md), rspec-puppet
  tests validating the rendered files with borgmatic, GitHub Actions CI and
  Forge release workflows.

**Bugfixes**

* The configuration template indented the `exclude_caches`,
  `keep_exclude_tags`, `exclude_nodump` and `borgmatic_source_directory`
  options as list items, which made the file invalid YAML, and did not quote
  values such as passphrases or commands.
* `borgmatic::repository` failed to compile with `encryptions` undef, as it
  reassigned the parameter.
* The authorized_keys line was matched on the whole key including its
  comment.
