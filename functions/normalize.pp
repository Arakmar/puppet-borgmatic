# @summary Prepares data for serialisation
#
# Drops the undef values of hashes and arrays and unwraps the Sensitive
# values, recursively. Key order is preserved.
#
# @param data The data to normalise.
# @return [Any] The data without undef nor Sensitive values.
function borgmatic::normalize(Any $data) >> Any {
  $data ? {
    Sensitive => borgmatic::normalize($data.unwrap),
    Hash      => Hash($data.filter |$key, $value| { $value =~ NotUndef }.map |$key, $value| {
        [$key, borgmatic::normalize($value)]
    }),
    Array     => $data.filter |$value| { $value =~ NotUndef }.map |$value| { borgmatic::normalize($value) },
    default   => $data,
  }
}
