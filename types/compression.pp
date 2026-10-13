# @summary A Borg compression specification
#
# @example
#   'zstd,3'
#   'auto,lzma,6'
type Borgmatic::Compression = Pattern[
  /\A(none|lz4)\z/,
  /\A(zstd|zlib|lzma)(,\d{1,2})?\z/,
  /\Aauto,(lz4|zstd|zlib|lzma)(,\d{1,2})?\z/,
  /\Aobfuscate,\d+,.+\z/,
]
