# @summary Tells whether data holds a Sensitive value, at any depth
#
# @param data The data to inspect.
# @return [Boolean] Whether a Sensitive value was found.
function borgmatic::contains_sensitive(Any $data) >> Boolean {
  $data ? {
    Sensitive => true,
    Hash      => $data.any |$key, $value| { borgmatic::contains_sensitive($value) },
    Array     => $data.any |$value| { borgmatic::contains_sensitive($value) },
    default   => false,
  }
}
