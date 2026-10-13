# @summary Lets an SSH key run `borg serve` as a user of the Borg server
#
# Adds to the authorized_keys file of `user` a line forcing `borg serve`
# with the given restrictions. The line is matched on the key type and
# body, so a key can only be authorized once per file.
#
# Without `restrict_to_paths` nor `restrict_to_repositories`, the key
# reaches every repository `user` can read.
#
# @example An append-only key for a monitoring user
#   borgmatic::authorized_key { 'client1_monitoring':
#     user              => 'borg-client1-check',
#     key               => 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample nrpe@client1',
#     restrict_to_paths => ['/srv/borg/client1'],
#     append_only       => true,
#   }
#
# @param key
#   Public key, `<type> <base64> [comment]`.
# @param user
#   User the key logs in as.
# @param ensure
#   Whether the key is present or absent.
# @param target
#   authorized_keys file, `/root/.ssh/authorized_keys` for root and
#   `/home/<user>/.ssh/authorized_keys` otherwise by default. Its directory
#   must exist.
# @param restrict_to_paths
#   `--restrict-to-path` values: the repositories the key reaches must be
#   under one of these paths.
# @param restrict_to_repositories
#   `--restrict-to-repository` values: the repositories the key reaches.
# @param append_only
#   Pass `--append-only`: the key can add archives but not delete them.
# @param umask
#   Umask of `borg serve`, which sets the mode of the files it writes.
# @param storage_quota
#   `--storage-quota` of the repositories created through this key.
# @param command
#   Forced command, replacing the `borg serve` command built from the
#   parameters above.
# @param options
#   Other authorized_keys options, appended to the forced command.
define borgmatic::authorized_key (
  Pattern[/\A(ssh-[a-z0-9-]+|ecdsa-sha2-nistp\d+|sk-[a-z0-9@.-]+)\s+[A-Za-z0-9+\/]+={0,3}(\s.*)?\z/] $key,
  String[1] $user,
  Enum['present', 'absent'] $ensure = 'present',
  Optional[Stdlib::Absolutepath] $target = undef,
  Array[Stdlib::Absolutepath] $restrict_to_paths = [],
  Array[Stdlib::Absolutepath] $restrict_to_repositories = [],
  Boolean $append_only = false,
  Optional[Borgmatic::Umask] $umask = undef,
  Optional[Borgmatic::StorageQuota] $storage_quota = undef,
  Optional[String[1]] $command = undef,
  Array[String[1]] $options = ['restrict'],
) {
  include borgmatic::server

  $_target = $target.lest || {
    $user ? {
      'root'  => '/root/.ssh/authorized_keys',
      default => "/home/${user}/.ssh/authorized_keys",
    }
  }

  $_command = $command.lest || {
    $serve_args = flatten(
      [$borgmatic::server::borg_command, 'serve'],
      $restrict_to_paths.map |$path| { ['--restrict-to-path', $path] },
      $restrict_to_repositories.map |$path| { ['--restrict-to-repository', $path] },
      $append_only ? { true => ['--append-only'], default => [] },
      $umask ? { undef => [], default => ['--umask', $umask] },
      $storage_quota ? { undef => [], default => ['--storage-quota', $storage_quota] },
    )
    shell_join($serve_args)
  }

  # sshd only unescapes \" inside an option value
  $forced_command = "command=\"${_command.regsubst('"', '\\"', 'G')}\""
  $key_fields = $key.split(/\s+/)

  file_line { "borgmatic::authorized_key ${title}":
    ensure            => $ensure,
    path              => $_target,
    line              => "${([$forced_command] + $options).join(',')} ${key}",
    match             => regexpescape("${key_fields[0]} ${key_fields[1]}"),
    match_for_absence => true,
  }
}
