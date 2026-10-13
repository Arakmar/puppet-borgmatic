# @summary Manages a borgmatic configuration file
#
# Writes `<config_dir>/<title>.yaml` in the flat format read by borgmatic
# 1.8 and later. Every borgmatic option set to a value other than undef is
# rendered under its borgmatic name, in the order of the borgmatic
# reference. Options without a parameter of their own go in `options`.
#
# An option is only understood by the borgmatic releases that know it:
# `commands`, for instance, needs borgmatic 2.0, whose older
# `before_*`/`after_*` hooks are deprecated but still supported. With
# `validate`, the file is checked by the installed borgmatic before being
# replaced.
#
# @see https://torsion.org/borgmatic/reference/configuration/
#
# @example Back up a host to two servers
#   borgmatic::config { 'system':
#     source_directories    => ['/etc', '/home', '/root', '/var'],
#     exclude_patterns      => ['/var/cache', '/var/tmp'],
#     repositories          => [
#       { 'path' => 'ssh://borg-client1@backup1.example.org/srv/borg/client1', 'label' => 'backup1' },
#       { 'path' => 'ssh://borg-client1@backup2.example.org/srv/borg/client1', 'label' => 'backup2' },
#     ],
#     encryption_passphrase => Sensitive('correct horse battery staple'),
#     keep_daily            => 7,
#     keep_weekly           => 4,
#     keep_monthly          => 6,
#     checks                => [{ 'name' => 'repository', 'frequency' => '2 weeks' }],
#     healthchecks          => 'https://hc-ping.com/your-uuid-here',
#   }
#
# @example Dump the MariaDB databases
#   borgmatic::config { 'databases':
#     repositories      => ['ssh://borg-client1@backup1.example.org/srv/borg/client1-db'],
#     mariadb_databases => [{ 'name' => 'all', 'username' => 'backup', 'password' => Sensitive('secret') }],
#   }
#
# @param ensure
#   Whether the configuration file is present or absent.
# @param path
#   Path of the configuration file, `<config_dir>/<title>.yaml` by default
#   where `config_dir` comes from class borgmatic. Another directory must be
#   managed separately.
# @param owner
#   Owner of the configuration file.
# @param group
#   Group of the configuration file.
# @param mode
#   Mode of the configuration file, which may hold passphrases.
# @param validate
#   Check the file with `borgmatic config validate` before replacing it.
# @param options
#   Other borgmatic options, keyed by their borgmatic name. They are merged
#   last and replace the options of the same name set by parameters.
# @param constants
#   Values interpolated as `{name}` in the other options.
# @param source_directories
#   Files and directories to back up.
# @param source_directories_must_exist
#   Fail when a source directory does not exist.
# @param repositories
#   Repositories to back up to, as paths or as hashes with at least a
#   `path`. A path is rendered as a hash, the form borgmatic expects since
#   1.8.
# @param working_directory
#   Directory the relative source directories and patterns are relative to.
# @param one_file_system
#   Stay in the same file system.
# @param numeric_ids
#   Only store numeric user and group identifiers (`numeric_owner` before
#   borgmatic 1.8).
# @param atime
#   Store the access time of the files.
# @param ctime
#   Store the change time of the files.
# @param birthtime
#   Store the creation time of the files.
# @param read_special
#   Read the content of special files such as devices and named pipes
#   instead of storing them as such. borgmatic enables it while dumping
#   databases.
# @param flags
#   Store the BSD flags of the files (`bsd_flags` before borgmatic 1.8).
# @param files_changed
#   How Borg 2 detects changed files.
# @param files_cache
#   Mode of the Borg files cache, for example `ctime,size,inode`.
# @param local_path
#   Local Borg executable.
# @param remote_path
#   Borg executable on the server.
# @param patterns
#   Borg patterns, for example `R /` or `- /home/*/.cache`.
# @param patterns_from
#   Files holding Borg patterns.
# @param exclude_patterns
#   Paths or patterns to exclude.
# @param exclude_from
#   Files holding exclude patterns.
# @param exclude_caches
#   Exclude the directories holding a `CACHEDIR.TAG` file.
# @param exclude_if_present
#   Exclude the directories holding one of these file names.
# @param keep_exclude_tags
#   Keep the tag files of the excluded directories.
# @param exclude_nodump
#   Exclude the files flagged NODUMP.
# @param user_runtime_directory
#   Runtime directory of borgmatic, for the database dumps among others.
# @param user_state_directory
#   State directory of borgmatic, for the check timestamps among others.
# @param encryption_passcommand
#   Command printing the repository passphrase.
# @param encryption_passphrase
#   Repository passphrase. A Sensitive value keeps the whole file out of
#   logs and reports.
# @param checkpoint_interval
#   Seconds between two checkpoints.
# @param checkpoint_volume
#   Bytes between two checkpoints.
# @param chunker_params
#   Borg chunker parameters.
# @param compression
#   Borg compression, for example `zstd,3`. Borg uses `lz4` when undef.
# @param recompress
#   When to recompress the data (the recreate action).
# @param upload_rate_limit
#   Upload rate limit in kiB/s (`remote_rate_limit` before borgmatic 1.8).
# @param upload_buffer_size
#   Size of the upload buffer in MiB.
# @param retries
#   Retries of a failing backup.
# @param retry_wait
#   Seconds to wait between two retries, doubled after each one.
# @param temporary_directory
#   Directory of the temporary files of Borg.
# @param ssh_command
#   SSH command used by Borg, for example `ssh -i /root/.ssh/id_backup`.
# @param borg_base_directory
#   Base directory of the Borg configuration and cache.
# @param borg_config_directory
#   Borg configuration directory.
# @param borg_cache_directory
#   Borg cache directory.
# @param use_chunks_archive
#   Whether Borg keeps the chunks cache archive.
# @param borg_files_cache_ttl
#   Number of backups a file stays in the files cache when missing.
# @param borg_security_directory
#   Borg security directory.
# @param borg_keys_directory
#   Borg keys directory.
# @param borg_key_file
#   Borg key file, with a keyfile encryption mode.
# @param borg_exit_codes
#   How to treat Borg exit codes. Since borgmatic 2.1 most Borg warnings
#   are errors, a code treated as a warning lets the backup succeed.
# @param umask
#   Umask of Borg and of the hooks, as an octal string such as `0077`. It
#   is rendered as the integer borgmatic expects (`77`).
# @param lock_wait
#   Seconds to wait for a repository lock.
# @param archive_name_format
#   Name of the archives, `{hostname}-{now}` by default.
# @param match_archives
#   Archives considered by prune, check and the other actions.
# @param relocated_repo_access_is_ok
#   Accept a repository that moved.
# @param unknown_unencrypted_repo_access_is_ok
#   Accept an unknown unencrypted repository.
# @param check_i_know_what_i_am_doing
#   Answer yes to the `check --repair` prompt.
# @param extra_borg_options
#   Extra flags of Borg commands, keyed by command (`create`, `prune`...).
# @param keep_within
#   Keep the archives within this period, for example `3H`.
# @param keep_secondly
#   Number of secondly archives to keep.
# @param keep_minutely
#   Number of minutely archives to keep.
# @param keep_hourly
#   Number of hourly archives to keep.
# @param keep_daily
#   Number of daily archives to keep.
# @param keep_weekly
#   Number of weekly archives to keep.
# @param keep_monthly
#   Number of monthly archives to keep.
# @param keep_yearly
#   Number of yearly archives to keep.
# @param keep_13weekly
#   Number of quarterly archives to keep, 13 weeks apart.
# @param keep_3monthly
#   Number of quarterly archives to keep, 3 months apart.
# @param compact_threshold
#   Minimum percentage of free space to reclaim when compacting.
# @param checks
#   Consistency checks, as names or as hashes with at least a `name`. A
#   name is rendered as a hash, the form borgmatic expects since 1.8.
#   borgmatic runs its default checks when undef, use `disabled` to skip
#   them.
# @param check_repositories
#   Repositories to check, all of them by default.
# @param check_last
#   Number of the most recent archives to check.
# @param verbosity
#   Console verbosity (borgmatic >= 2.0).
# @param syslog_verbosity
#   Syslog verbosity (borgmatic >= 2.0).
# @param log_file
#   Log file (borgmatic >= 2.0).
# @param log_file_verbosity
#   Log file verbosity (borgmatic >= 2.0).
# @param log_file_format
#   Format of the log file lines (borgmatic >= 2.0).
# @param monitoring_verbosity
#   Verbosity of the logs sent to the monitoring hooks (borgmatic >= 2.0).
# @param statistics
#   Statistics to display, `standard`, `quick` or `none` (a boolean before
#   borgmatic 2.1).
# @param default_actions
#   Whether to run the default actions when borgmatic is run without any.
# @param skip_actions
#   Actions to skip.
# @param commands
#   Command hooks (borgmatic >= 2.0), replacing the `before_*`, `after_*`
#   and `on_error` hooks.
# @param before_actions
#   Deprecated, use `commands`. Commands run before the actions of each
#   repository.
# @param before_backup
#   Deprecated, use `commands`. Commands run before each create action.
# @param before_prune
#   Deprecated, use `commands`. Commands run before each prune action.
# @param before_compact
#   Deprecated, use `commands`. Commands run before each compact action.
# @param before_check
#   Deprecated, use `commands`. Commands run before each check action.
# @param before_extract
#   Deprecated, use `commands`. Commands run before each extract action.
# @param after_backup
#   Deprecated, use `commands`. Commands run after each create action.
# @param after_compact
#   Deprecated, use `commands`. Commands run after each compact action.
# @param after_prune
#   Deprecated, use `commands`. Commands run after each prune action.
# @param after_check
#   Deprecated, use `commands`. Commands run after each check action.
# @param after_extract
#   Deprecated, use `commands`. Commands run after each extract action.
# @param after_actions
#   Deprecated, use `commands`. Commands run after the actions of each
#   repository.
# @param on_error
#   Deprecated, use `commands`. Commands run when an action fails.
# @param before_everything
#   Deprecated, use `commands`. Commands run once before everything, when
#   creating backups.
# @param after_everything
#   Deprecated, use `commands`. Commands run once after everything, when
#   creating backups.
# @param postgresql_databases
#   PostgreSQL databases to dump.
# @param mariadb_databases
#   MariaDB databases to dump.
# @param mysql_databases
#   MySQL databases to dump.
# @param sqlite_databases
#   SQLite databases to dump.
# @param mongodb_databases
#   MongoDB databases to dump.
# @param ntfy
#   ntfy monitoring hook.
# @param pushover
#   Pushover monitoring hook.
# @param zabbix
#   Zabbix monitoring hook.
# @param apprise
#   Apprise monitoring hook.
# @param healthchecks
#   Healthchecks monitoring hook, as a hash or as the ping URL.
# @param uptime_kuma
#   Uptime Kuma monitoring hook.
# @param cronitor
#   Cronitor monitoring hook, as a hash or as the ping URL.
# @param pagerduty
#   PagerDuty monitoring hook, as a hash or as the integration key.
# @param loki
#   Grafana Loki monitoring hook.
# @param sentry
#   Sentry monitoring hook.
# @param zfs
#   ZFS snapshot hook, `{}` to enable it with its defaults.
# @param btrfs
#   Btrfs snapshot hook, `{}` to enable it with its defaults.
# @param lvm
#   LVM snapshot hook, `{}` to enable it with its defaults.
define borgmatic::config (
  Enum['present', 'absent'] $ensure = 'present',
  Optional[Stdlib::Absolutepath] $path = undef,
  String[1] $owner = 'root',
  String[1] $group = 'root',
  Stdlib::Filemode $mode = '0600',
  Boolean $validate = true,
  Hash[String[1], Any] $options = {},
  # Sources
  Optional[Hash[String[1], Any]] $constants = undef,
  Optional[Array[String[1]]] $source_directories = undef,
  Optional[Boolean] $source_directories_must_exist = undef,
  Array[Borgmatic::RepositoryEntry] $repositories = [],
  Optional[Stdlib::Absolutepath] $working_directory = undef,
  Optional[Boolean] $one_file_system = undef,
  Optional[Boolean] $numeric_ids = undef,
  Optional[Boolean] $atime = undef,
  Optional[Boolean] $ctime = undef,
  Optional[Boolean] $birthtime = undef,
  Optional[Boolean] $read_special = undef,
  Optional[Boolean] $flags = undef,
  Optional[Enum['ctime', 'mtime', 'disabled']] $files_changed = undef,
  Optional[String[1]] $files_cache = undef,
  Optional[String[1]] $local_path = undef,
  Optional[String[1]] $remote_path = undef,
  Optional[Array[String[1]]] $patterns = undef,
  Optional[Array[Stdlib::Absolutepath]] $patterns_from = undef,
  Optional[Array[String[1]]] $exclude_patterns = undef,
  Optional[Array[Stdlib::Absolutepath]] $exclude_from = undef,
  Optional[Boolean] $exclude_caches = undef,
  Optional[Array[String[1]]] $exclude_if_present = undef,
  Optional[Boolean] $keep_exclude_tags = undef,
  Optional[Boolean] $exclude_nodump = undef,
  Optional[Stdlib::Absolutepath] $user_runtime_directory = undef,
  Optional[Stdlib::Absolutepath] $user_state_directory = undef,
  # Storage
  Optional[String[1]] $encryption_passcommand = undef,
  Optional[Borgmatic::Secret] $encryption_passphrase = undef,
  Optional[Integer[0]] $checkpoint_interval = undef,
  Optional[Integer[0]] $checkpoint_volume = undef,
  Optional[String[1]] $chunker_params = undef,
  Optional[Borgmatic::Compression] $compression = undef,
  Optional[Enum['if-different', 'always', 'never']] $recompress = undef,
  Optional[Integer[0]] $upload_rate_limit = undef,
  Optional[Integer[0]] $upload_buffer_size = undef,
  Optional[Integer[0]] $retries = undef,
  Optional[Integer[0]] $retry_wait = undef,
  Optional[Stdlib::Absolutepath] $temporary_directory = undef,
  Optional[String[1]] $ssh_command = undef,
  Optional[Stdlib::Absolutepath] $borg_base_directory = undef,
  Optional[Stdlib::Absolutepath] $borg_config_directory = undef,
  Optional[Stdlib::Absolutepath] $borg_cache_directory = undef,
  Optional[Boolean] $use_chunks_archive = undef,
  Optional[Integer[0]] $borg_files_cache_ttl = undef,
  Optional[Stdlib::Absolutepath] $borg_security_directory = undef,
  Optional[Stdlib::Absolutepath] $borg_keys_directory = undef,
  Optional[Stdlib::Absolutepath] $borg_key_file = undef,
  Optional[Array[Struct[{ 'code' => Integer[1], 'treat_as' => Enum['error', 'warning'] }]]] $borg_exit_codes = undef,
  Optional[Borgmatic::Umask] $umask = undef,
  Optional[Integer[0]] $lock_wait = undef,
  Optional[String[1]] $archive_name_format = undef,
  Optional[String[1]] $match_archives = undef,
  Optional[Boolean] $relocated_repo_access_is_ok = undef,
  Optional[Boolean] $unknown_unencrypted_repo_access_is_ok = undef,
  Optional[Boolean] $check_i_know_what_i_am_doing = undef,
  Optional[Hash[Pattern[/\A[a-z_]+\z/], String[1]]] $extra_borg_options = undef,
  # Retention
  Optional[String[1]] $keep_within = undef,
  Optional[Integer[0]] $keep_secondly = undef,
  Optional[Integer[0]] $keep_minutely = undef,
  Optional[Integer[0]] $keep_hourly = undef,
  Optional[Integer[0]] $keep_daily = undef,
  Optional[Integer[0]] $keep_weekly = undef,
  Optional[Integer[0]] $keep_monthly = undef,
  Optional[Integer[0]] $keep_yearly = undef,
  Optional[Integer[0]] $keep_13weekly = undef,
  Optional[Integer[0]] $keep_3monthly = undef,
  Optional[Integer[0, 100]] $compact_threshold = undef,
  # Consistency
  Optional[Array[Borgmatic::Check]] $checks = undef,
  Optional[Array[String[1]]] $check_repositories = undef,
  Optional[Integer[1]] $check_last = undef,
  # Output
  Optional[Borgmatic::Verbosity] $verbosity = undef,
  Optional[Borgmatic::Verbosity] $syslog_verbosity = undef,
  Optional[Stdlib::Absolutepath] $log_file = undef,
  Optional[Borgmatic::Verbosity] $log_file_verbosity = undef,
  Optional[String[1]] $log_file_format = undef,
  Optional[Borgmatic::Verbosity] $monitoring_verbosity = undef,
  Optional[Variant[Boolean, Enum['standard', 'quick', 'none']]] $statistics = undef,
  Optional[Boolean] $default_actions = undef,
  Optional[Array[Borgmatic::Action]] $skip_actions = undef,
  # Hooks
  Optional[Array[Borgmatic::Command]] $commands = undef,
  Optional[Array[String[1]]] $before_actions = undef,
  Optional[Array[String[1]]] $before_backup = undef,
  Optional[Array[String[1]]] $before_prune = undef,
  Optional[Array[String[1]]] $before_compact = undef,
  Optional[Array[String[1]]] $before_check = undef,
  Optional[Array[String[1]]] $before_extract = undef,
  Optional[Array[String[1]]] $after_backup = undef,
  Optional[Array[String[1]]] $after_compact = undef,
  Optional[Array[String[1]]] $after_prune = undef,
  Optional[Array[String[1]]] $after_check = undef,
  Optional[Array[String[1]]] $after_extract = undef,
  Optional[Array[String[1]]] $after_actions = undef,
  Optional[Array[String[1]]] $on_error = undef,
  Optional[Array[String[1]]] $before_everything = undef,
  Optional[Array[String[1]]] $after_everything = undef,
  Optional[Array[Borgmatic::Settings]] $postgresql_databases = undef,
  Optional[Array[Borgmatic::Settings]] $mariadb_databases = undef,
  Optional[Array[Borgmatic::Settings]] $mysql_databases = undef,
  Optional[Array[Borgmatic::Settings]] $sqlite_databases = undef,
  Optional[Array[Borgmatic::Settings]] $mongodb_databases = undef,
  Optional[Borgmatic::Settings] $ntfy = undef,
  Optional[Borgmatic::Settings] $pushover = undef,
  Optional[Borgmatic::Settings] $zabbix = undef,
  Optional[Borgmatic::Settings] $apprise = undef,
  Optional[Variant[String[1], Borgmatic::Settings]] $healthchecks = undef,
  Optional[Borgmatic::Settings] $uptime_kuma = undef,
  Optional[Variant[String[1], Borgmatic::Settings]] $cronitor = undef,
  Optional[Variant[Borgmatic::Secret, Borgmatic::Settings]] $pagerduty = undef,
  Optional[Borgmatic::Settings] $loki = undef,
  Optional[Borgmatic::Settings] $sentry = undef,
  Optional[Borgmatic::Settings] $zfs = undef,
  Optional[Borgmatic::Settings] $btrfs = undef,
  Optional[Borgmatic::Settings] $lvm = undef,
) {
  include borgmatic

  $_path = $path.lest || { "${borgmatic::config_dir}/${title}.yaml" }

  if $ensure == 'present' {
    if $repositories.empty and !('repositories' in $options) {
      fail("Borgmatic::Config[${title}]: at least one repository is required")
    }

    $config = {
      'constants'                             => $constants,
      'source_directories'                    => $source_directories,
      'source_directories_must_exist'         => $source_directories_must_exist,
      'repositories'                          => $repositories.map |$repository| {
        $repository ? {
          String  => { 'path' => $repository },
          default => $repository,
        }
      },
      'working_directory'                     => $working_directory,
      'one_file_system'                       => $one_file_system,
      'numeric_ids'                           => $numeric_ids,
      'atime'                                 => $atime,
      'ctime'                                 => $ctime,
      'birthtime'                             => $birthtime,
      'read_special'                          => $read_special,
      'flags'                                 => $flags,
      'files_changed'                         => $files_changed,
      'files_cache'                           => $files_cache,
      'local_path'                            => $local_path,
      'remote_path'                           => $remote_path,
      'patterns'                              => $patterns,
      'patterns_from'                         => $patterns_from,
      'exclude_patterns'                      => $exclude_patterns,
      'exclude_from'                          => $exclude_from,
      'exclude_caches'                        => $exclude_caches,
      'exclude_if_present'                    => $exclude_if_present,
      'keep_exclude_tags'                     => $keep_exclude_tags,
      'exclude_nodump'                        => $exclude_nodump,
      'user_runtime_directory'                => $user_runtime_directory,
      'user_state_directory'                  => $user_state_directory,
      'encryption_passcommand'                => $encryption_passcommand,
      'encryption_passphrase'                 => $encryption_passphrase,
      'checkpoint_interval'                   => $checkpoint_interval,
      'checkpoint_volume'                     => $checkpoint_volume,
      'chunker_params'                        => $chunker_params,
      'compression'                           => $compression,
      'recompress'                            => $recompress,
      'upload_rate_limit'                     => $upload_rate_limit,
      'upload_buffer_size'                    => $upload_buffer_size,
      'retries'                               => $retries,
      'retry_wait'                            => $retry_wait,
      'temporary_directory'                   => $temporary_directory,
      'ssh_command'                           => $ssh_command,
      'borg_base_directory'                   => $borg_base_directory,
      'borg_config_directory'                 => $borg_config_directory,
      'borg_cache_directory'                  => $borg_cache_directory,
      'use_chunks_archive'                    => $use_chunks_archive,
      'borg_files_cache_ttl'                  => $borg_files_cache_ttl,
      'borg_security_directory'               => $borg_security_directory,
      'borg_keys_directory'                   => $borg_keys_directory,
      'borg_key_file'                         => $borg_key_file,
      'borg_exit_codes'                       => $borg_exit_codes,
      # borgmatic hands the integer to Borg, which reads it as octal
      'umask'                                 => $umask.then |$value| { Integer($value, 10) },
      'lock_wait'                             => $lock_wait,
      'archive_name_format'                   => $archive_name_format,
      'match_archives'                        => $match_archives,
      'relocated_repo_access_is_ok'           => $relocated_repo_access_is_ok,
      'unknown_unencrypted_repo_access_is_ok' => $unknown_unencrypted_repo_access_is_ok,
      'check_i_know_what_i_am_doing'          => $check_i_know_what_i_am_doing,
      'extra_borg_options'                    => $extra_borg_options,
      'keep_within'                           => $keep_within,
      'keep_secondly'                         => $keep_secondly,
      'keep_minutely'                         => $keep_minutely,
      'keep_hourly'                           => $keep_hourly,
      'keep_daily'                            => $keep_daily,
      'keep_weekly'                           => $keep_weekly,
      'keep_monthly'                          => $keep_monthly,
      'keep_yearly'                           => $keep_yearly,
      'keep_13weekly'                         => $keep_13weekly,
      'keep_3monthly'                         => $keep_3monthly,
      'compact_threshold'                     => $compact_threshold,
      'checks'                                => $checks.then |$value| {
        $value.map |$check| {
          $check ? {
            String  => { 'name' => $check },
            default => $check,
          }
        }
      },
      'check_repositories'                    => $check_repositories,
      'check_last'                            => $check_last,
      'verbosity'                             => $verbosity,
      'syslog_verbosity'                      => $syslog_verbosity,
      'log_file'                              => $log_file,
      'log_file_verbosity'                    => $log_file_verbosity,
      'log_file_format'                       => $log_file_format,
      'monitoring_verbosity'                  => $monitoring_verbosity,
      'statistics'                            => $statistics,
      'default_actions'                       => $default_actions,
      'skip_actions'                          => $skip_actions,
      'commands'                              => $commands,
      'before_actions'                        => $before_actions,
      'before_backup'                         => $before_backup,
      'before_prune'                          => $before_prune,
      'before_compact'                        => $before_compact,
      'before_check'                          => $before_check,
      'before_extract'                        => $before_extract,
      'after_backup'                          => $after_backup,
      'after_compact'                         => $after_compact,
      'after_prune'                           => $after_prune,
      'after_check'                           => $after_check,
      'after_extract'                         => $after_extract,
      'after_actions'                         => $after_actions,
      'on_error'                              => $on_error,
      'before_everything'                     => $before_everything,
      'after_everything'                      => $after_everything,
      'postgresql_databases'                  => $postgresql_databases,
      'mariadb_databases'                     => $mariadb_databases,
      'mysql_databases'                       => $mysql_databases,
      'sqlite_databases'                      => $sqlite_databases,
      'mongodb_databases'                     => $mongodb_databases,
      'ntfy'                                  => $ntfy,
      'pushover'                              => $pushover,
      'zabbix'                                => $zabbix,
      'apprise'                               => $apprise,
      'healthchecks'                          => $healthchecks ? {
        String  => { 'ping_url' => $healthchecks },
        default => $healthchecks,
      },
      'uptime_kuma'                           => $uptime_kuma,
      'cronitor'                              => $cronitor ? {
        String  => { 'ping_url' => $cronitor },
        default => $cronitor,
      },
      'pagerduty'                             => $pagerduty ? {
        Borgmatic::Secret => { 'integration_key' => $pagerduty },
        default           => $pagerduty,
      },
      'loki'                                  => $loki,
      'sentry'                                => $sentry,
      'zfs'                                   => $zfs,
      'btrfs'                                 => $btrfs,
      'lvm'                                   => $lvm,
    } + $options

    $content = borgmatic::to_yaml($config)
  } else {
    $content = undef
  }

  $validate_cmd = $validate ? {
    true    => "${borgmatic::binary_path} --config % config validate",
    default => undef,
  }

  file { $_path:
    ensure       => stdlib::ensure($ensure, 'file'),
    owner        => $owner,
    group        => $group,
    mode         => $mode,
    content      => $content,
    validate_cmd => $validate_cmd,
    require      => Class['borgmatic::install'],
  }
}
