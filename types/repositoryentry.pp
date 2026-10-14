# @summary A repository of a borgmatic configuration file
#
# A string is the path of the repository, the other keys are those of the
# `repositories` option of borgmatic.
#
# @example
#   'ssh://borg@backup.example.org/srv/borg/client1'
#   { 'path' => 'ssh://borg@backup.example.org/srv/borg/client1', 'label' => 'backup' }
type Borgmatic::RepositoryEntry = Variant[
  String[1],
  Struct[{
    'path'                              => String[1],
    Optional['label']                   => String[1],
    Optional['encryption']              => String[1],
    Optional['append_only']             => Boolean,
    Optional['storage_quota']           => Borgmatic::StorageQuota,
    Optional['make_parent_directories'] => Boolean,
  }],
]
