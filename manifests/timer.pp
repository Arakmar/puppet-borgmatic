# @summary Runs borgmatic on a schedule with a systemd timer
#
# Declares the `borgmatic-<title>.service` oneshot unit running borgmatic
# for one configuration file or directory, and the
# `borgmatic-<title>.timer` unit starting it. With `persistent`, a run
# missed while the host was off happens at the next boot, which a cron job
# cannot do. The service runs with a low CPU and I/O priority.
#
# Logging flags are command line options rather than configuration
# options because borgmatic only reads them from the configuration since
# version 2.0.
#
# @example Nightly backups logged to a file
#   borgmatic::timer { 'system':
#     on_calendar        => '*-*-* 01:00:00',
#     verbosity          => -1,
#     syslog_verbosity   => 1,
#     log_file           => '/var/log/borgmatic/system.log',
#     log_file_verbosity => 1,
#   }
#
# @param ensure
#   Whether the units are present or absent.
# @param config
#   Configuration file or directory to run, `<config_dir>/<title>.yaml` by
#   default where `config_dir` comes from class borgmatic.
# @param on_calendar
#   When to run, as one or more systemd `OnCalendar` expressions.
# @param enable
#   Whether to enable and start the timer. When false the units are kept,
#   so the service can still be started by hand or by another unit.
# @param persistent
#   Run at boot when a run was missed while the host was off.
# @param randomized_delay_sec
#   Random delay added to each run, to spread the load of several timers.
# @param actions
#   Actions to run, borgmatic runs its default actions (create, prune,
#   compact and check) when empty.
# @param verbosity
#   `--verbosity` flag, the console output ending up in the journal.
# @param syslog_verbosity
#   `--syslog-verbosity` flag.
# @param log_file
#   `--log-file` flag.
# @param log_file_verbosity
#   `--log-file-verbosity` flag.
# @param extra_args
#   Other borgmatic flags, placed before the actions.
# @param nice
#   `Nice` of the service.
# @param cpu_scheduling_policy
#   `CPUSchedulingPolicy` of the service.
# @param io_scheduling_class
#   `IOSchedulingClass` of the service.
# @param io_scheduling_priority
#   `IOSchedulingPriority` of the service.
# @param unit_entry
#   Settings merged into the `[Unit]` section of the service.
# @param service_entry
#   Settings merged into the `[Service]` section of the service. An empty
#   string resets a setting to the systemd default, for example
#   `{ 'Nice' => '' }`.
# @param timer_entry
#   Settings merged into the `[Timer]` section of the timer.
define borgmatic::timer (
  Enum['present', 'absent'] $ensure = 'present',
  Optional[Stdlib::Absolutepath] $config = undef,
  Variant[String[1], Array[String[1], 1]] $on_calendar = 'daily',
  Boolean $enable = true,
  Boolean $persistent = true,
  Optional[Systemd::Timespan] $randomized_delay_sec = undef,
  Array[Borgmatic::Action] $actions = [],
  Optional[Borgmatic::Verbosity] $verbosity = undef,
  Optional[Borgmatic::Verbosity] $syslog_verbosity = undef,
  Optional[Stdlib::Absolutepath] $log_file = undef,
  Optional[Borgmatic::Verbosity] $log_file_verbosity = undef,
  Array[String[1]] $extra_args = [],
  Integer[-20, 19] $nice = 19,
  Enum['other', 'batch', 'idle', 'fifo', 'rr'] $cpu_scheduling_policy = 'batch',
  Enum['realtime', 'best-effort', 'idle'] $io_scheduling_class = 'best-effort',
  Integer[0, 7] $io_scheduling_priority = 7,
  Systemd::Unit::Unit $unit_entry = {},
  Systemd::Unit::Service $service_entry = {},
  Systemd::Unit::Timer $timer_entry = {},
) {
  include borgmatic

  $unit = "borgmatic-${title}"
  $_config = $config.lest || { "${borgmatic::config_dir}/${title}.yaml" }

  $flags = {
    '--verbosity'          => $verbosity,
    '--syslog-verbosity'   => $syslog_verbosity,
    '--log-file'           => $log_file,
    '--log-file-verbosity' => $log_file_verbosity,
  }.filter |$flag, $value| { $value =~ NotUndef }

  $exec_start = flatten(
    $borgmatic::binary_path,
    $flags.map |$flag, $value| { [$flag, String($value)] },
    $extra_args,
    '--config', $_config,
    $actions,
  ).join(' ')

  systemd::manage_unit { "${unit}.service":
    ensure        => $ensure,
    unit_entry    => {
      'Description' => "borgmatic backup ${title}",
      'Wants'       => 'network-online.target',
      'After'       => 'network-online.target',
    } + $unit_entry,
    service_entry => {
      'Type'                 => 'oneshot',
      'ExecStart'            => $exec_start,
      'Nice'                 => $nice,
      'CPUSchedulingPolicy'  => $cpu_scheduling_policy,
      'IOSchedulingClass'    => $io_scheduling_class,
      'IOSchedulingPriority' => $io_scheduling_priority,
    } + $service_entry,
  }

  $timer_active = $ensure == 'present' and $enable

  systemd::manage_unit { "${unit}.timer":
    ensure        => $ensure,
    unit_entry    => {
      'Description' => "borgmatic backup ${title} timer",
    },
    timer_entry   => {
      'OnCalendar'         => $on_calendar,
      'Persistent'         => $persistent,
      'RandomizedDelaySec' => $randomized_delay_sec,
    }.filter |$key, $value| { $value =~ NotUndef } + $timer_entry,
    install_entry => {
      'WantedBy' => 'timers.target',
    },
    enable        => $timer_active,
    active        => $timer_active,
  }

  if $ensure == 'present' {
    Class['borgmatic::install'] -> Systemd::Manage_unit["${unit}.timer"]
    Systemd::Manage_unit["${unit}.service"] -> Systemd::Manage_unit["${unit}.timer"]
  }
}
