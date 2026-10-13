# @summary Creates a Borg repository for a borgmatic client
#
# The repository directory is created with the given owner, group and
# mode, then initialised by `borg init` (Borg 1.x) running as root, the
# files it wrote being handed over to the owner. An existing repository is
# left alone: changing `encryption` or `passphrase` afterwards has no
# effect on it, and removing the resource keeps it on disk.
#
# Clients usually export this resource, tagged for their backup server,
# which collects it after declaring borgmatic::server.
#
# @example A repository reachable by the root key of a client
#   borgmatic::repository { 'client1':
#     owner           => 'borg-client1',
#     passphrase      => Sensitive('correct horse battery staple'),
#     authorized_keys => {
#       'root' => {
#         'key' => 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample root@client1',
#       },
#     },
#   }
#
# @param path
#   Path of the repository, `<base_path>/<title>` by default where
#   `base_path` comes from borgmatic::server.
# @param owner
#   User owning the repository, the one borgmatic logs in as.
# @param group
#   Group of the repository, the owner by default.
# @param mode
#   Mode of the repository directory.
# @param encryption
#   Encryption mode passed to `borg init`, the `encryption` of
#   borgmatic::server by default.
# @param passphrase
#   Passphrase of the repository key, required unless `encryption` is
#   `none`. It must match the `encryption_passphrase` of the client.
# @param umask
#   Umask of `borg init`, for example `0027` to let the group read the
#   repository. It is also the default umask of `authorized_keys`.
# @param append_only
#   Create the repository in append-only mode.
# @param storage_quota
#   Storage quota of the repository, for example `500G`.
# @param authorized_keys
#   borgmatic::authorized_key resources reaching this repository, keyed by
#   a name unique within it. Their `user` defaults to `owner`,
#   `restrict_to_paths` to `path` and `umask` to `umask`.
define borgmatic::repository (
  Optional[Stdlib::Absolutepath] $path = undef,
  String[1] $owner = 'root',
  String[1] $group = $owner,
  Stdlib::Filemode $mode = '0700',
  Optional[Borgmatic::Encryption] $encryption = undef,
  Optional[Borgmatic::Secret] $passphrase = undef,
  Optional[Borgmatic::Umask] $umask = undef,
  Boolean $append_only = false,
  Optional[Borgmatic::StorageQuota] $storage_quota = undef,
  Hash[String[1], Hash[String[1], Any]] $authorized_keys = {},
) {
  include borgmatic::server

  $_path = $path.lest || { "${borgmatic::server::base_path}/${title}" }
  $_encryption = $encryption.lest || { $borgmatic::server::encryption }

  if $_encryption == 'none' {
    $environment = []
  } elsif $passphrase =~ Undef {
    fail("Borgmatic::Repository[${title}]: a passphrase is required with the ${_encryption} encryption")
  } else {
    # exec can only redact command, unless and onlyif and warns about any
    # other Sensitive parameter. The environment is never logged, and unlike
    # the command line it does not show up in the process list.
    $environment = ["BORG_PASSPHRASE=${passphrase.unwrap}"]
  }

  $umask_args = $umask ? {
    undef   => [],
    default => ['--umask', $umask],
  }
  $append_only_args = $append_only ? {
    true    => ['--append-only'],
    default => [],
  }
  $storage_quota_args = $storage_quota ? {
    undef   => [],
    default => ['--storage-quota', $storage_quota],
  }

  $init = shell_join(
    [$borgmatic::server::borg_command, 'init', '--encryption', $_encryption]
    + $umask_args + $append_only_args + $storage_quota_args + [$_path]
  )
  $chown = shell_join(['chown', '-R', "${owner}:${group}", $_path])

  file { $_path:
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => $mode,
  }

  exec { "borg init ${_path}":
    command     => "${init} && ${chown}",
    creates     => "${_path}/config",
    environment => $environment,
    provider    => 'shell',
    require     => File[$_path],
  }

  if $borgmatic::server::manage_package {
    Package[$borgmatic::server::package_name] -> Exec["borg init ${_path}"]
  }

  $authorized_keys.each |String[1] $key_name, Hash[String[1], Any] $params| {
    borgmatic::authorized_key { "${title}_${key_name}":
      * => {
        'user'              => $owner,
        'restrict_to_paths' => [$_path],
        'umask'             => $umask,
      } + $params,
    }
  }
}
