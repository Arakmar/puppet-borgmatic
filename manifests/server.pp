# @summary Hosts the Borg repositories borgmatic clients back up to
#
# Installs Borg and manages the directory holding the repositories. The
# repositories and the SSH keys allowed to reach them are
# borgmatic::repository and borgmatic::authorized_key resources, declared
# directly, through the `repositories` and `authorized_keys` hashes or
# collected from the resources exported by the clients.
#
# @example A server collecting the repositories exported by its clients
#   class { 'borgmatic::server':
#     base_path => '/srv/borg',
#     group     => 'borgmatic',
#     mode      => '0750',
#   }
#
#   Borgmatic::Repository <<| tag == "borgmatic_${facts['networking']['fqdn']}" |>>
#   Borgmatic::Authorized_key <<| tag == "borgmatic_${facts['networking']['fqdn']}" |>>
#
# @param package_name
#   Name of the Borg package, `borgbackup` (`borg` on Arch Linux) from module data.
# @param manage_package
#   Whether to install Borg.
# @param package_ensure
#   Ensure value of the Borg package.
# @param borg_command
#   Borg executable, used to create the repositories and in the forced
#   command of the authorized keys.
# @param manage_base_path
#   Whether to manage the `base_path` directory.
# @param base_path
#   Directory holding the repositories. The path of a repository defaults to
#   `<base_path>/<title>`.
# @param owner
#   Owner of `base_path`.
# @param group
#   Group of `base_path`.
# @param mode
#   Mode of `base_path`. The users owning the repositories must be able to
#   traverse it.
# @param encryption
#   Default encryption mode of the repositories.
# @param repositories
#   borgmatic::repository resources to declare, keyed by title.
# @param authorized_keys
#   borgmatic::authorized_key resources to declare, keyed by title.
class borgmatic::server (
  String[1] $package_name,
  Boolean $manage_package = true,
  String[1] $package_ensure = 'installed',
  Stdlib::Absolutepath $borg_command = '/usr/bin/borg',
  Boolean $manage_base_path = true,
  Stdlib::Absolutepath $base_path = '/srv/borg',
  String[1] $owner = 'root',
  String[1] $group = 'root',
  Stdlib::Filemode $mode = '0755',
  Borgmatic::Encryption $encryption = 'repokey-blake2',
  Hash[String[1], Hash[String[1], Any]] $repositories = {},
  Hash[String[1], Hash[String[1], Any]] $authorized_keys = {},
) {
  if $manage_package {
    package { $package_name:
      ensure => $package_ensure,
    }
  }

  if $manage_base_path {
    file { $base_path:
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
    }
  }

  $repositories.each |String[1] $title, Hash[String[1], Any] $params| {
    borgmatic::repository { $title:
      * => $params,
    }
  }

  $authorized_keys.each |String[1] $title, Hash[String[1], Any] $params| {
    borgmatic::authorized_key { $title:
      * => $params,
    }
  }
}
