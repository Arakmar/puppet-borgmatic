# @summary Installs borgmatic
#
# @api private
class borgmatic::install {
  assert_private()

  if $borgmatic::manage_package {
    package { $borgmatic::package_name:
      ensure => $borgmatic::package_ensure,
    }
  }
}
