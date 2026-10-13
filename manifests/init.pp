# @summary Installs borgmatic and manages its configuration directory
#
# The configurations themselves are borgmatic::config resources and their
# schedules borgmatic::timer resources, declared directly or through the
# `configs` and `timers` hashes.
#
# @example A configuration backed up every night
#   include borgmatic
#
#   borgmatic::config { 'system':
#     source_directories    => ['/etc', '/home', '/root', '/var'],
#     repositories          => ['ssh://borg-client1@backup.example.org/srv/borg/client1'],
#     encryption_passphrase => Sensitive('correct horse battery staple'),
#     keep_daily            => 7,
#   }
#
#   borgmatic::timer { 'system':
#     on_calendar => '*-*-* 01:00:00',
#   }
#
# @param manage_package
#   Whether to install borgmatic.
# @param package_name
#   Name of the borgmatic package.
# @param package_ensure
#   Ensure value of the borgmatic package.
# @param binary_path
#   borgmatic executable, used to validate the configurations and by the
#   timers.
# @param manage_config_dir
#   Whether to manage `config_dir`.
# @param config_dir
#   Directory of the configurations, where borgmatic::config writes
#   `<title>.yaml` by default.
# @param config_dir_owner
#   Owner of `config_dir`.
# @param config_dir_group
#   Group of `config_dir`.
# @param config_dir_mode
#   Mode of `config_dir`.
# @param purge_config_dir
#   Remove the files of `config_dir` that Puppet does not manage.
# @param package_timer
#   State of the `borgmatic.timer` unit shipped by some packages, which runs
#   every configuration of `/etc/borgmatic.d` daily: `true` enables and
#   starts it, `false` stops and disables it (when borgmatic::timer
#   schedules the configurations instead), undef leaves it alone.
# @param configs
#   borgmatic::config resources to declare, keyed by title.
# @param timers
#   borgmatic::timer resources to declare, keyed by title.
class borgmatic (
  Boolean $manage_package = true,
  String[1] $package_name = 'borgmatic',
  String[1] $package_ensure = 'installed',
  Stdlib::Absolutepath $binary_path = '/usr/bin/borgmatic',
  Boolean $manage_config_dir = true,
  Stdlib::Absolutepath $config_dir = '/etc/borgmatic.d',
  String[1] $config_dir_owner = 'root',
  String[1] $config_dir_group = 'root',
  Stdlib::Filemode $config_dir_mode = '0755',
  Boolean $purge_config_dir = false,
  Optional[Boolean] $package_timer = undef,
  Hash[String[1], Hash[String[1], Any]] $configs = {},
  Hash[String[1], Hash[String[1], Any]] $timers = {},
) {
  contain borgmatic::install

  if $manage_config_dir {
    file { $config_dir:
      ensure  => directory,
      owner   => $config_dir_owner,
      group   => $config_dir_group,
      mode    => $config_dir_mode,
      purge   => $purge_config_dir,
      recurse => $purge_config_dir,
      force   => $purge_config_dir,
      require => Class['borgmatic::install'],
    }
  }

  if $package_timer =~ NotUndef {
    $package_timer_ensure = $package_timer ? {
      true    => 'running',
      default => 'stopped',
    }

    service { 'borgmatic.timer':
      ensure  => $package_timer_ensure,
      enable  => $package_timer,
      require => Class['borgmatic::install'],
    }
  }

  $configs.each |String[1] $title, Hash[String[1], Any] $params| {
    borgmatic::config { $title:
      * => $params,
    }
  }

  $timers.each |String[1] $title, Hash[String[1], Any] $params| {
    borgmatic::timer { $title:
      * => $params,
    }
  }
}
