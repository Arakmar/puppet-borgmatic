# @summary A Borg storage quota, a size with an optional unit suffix
#
# @example
#   '500G'
type Borgmatic::StorageQuota = Pattern[/\A\d+(\.\d+)?[KMGTPEZY]?\z/]
