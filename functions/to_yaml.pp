# @summary Renders a borgmatic configuration file
#
# Undef options are left out and long values are never folded. The result
# is Sensitive when the configuration holds a Sensitive value, such as the
# encryption passphrase, so that it stays out of logs and reports.
#
# @param config The borgmatic options.
# @return [Variant[String, Sensitive[String]]] The YAML document.
function borgmatic::to_yaml(Hash[String[1], Any] $config) >> Variant[String, Sensitive[String]] {
  $yaml = "# Managed by Puppet\n${stdlib::to_yaml(borgmatic::normalize($config), { 'line_width' => -1 })}"

  borgmatic::contains_sensitive($config) ? {
    true    => Sensitive($yaml),
    default => $yaml,
  }
}
