# @summary Encryption mode of a repository created with `borg init` (Borg 1.x)
#
# The keyfile modes are left out: the key would stay on the server, where
# the borgmatic client cannot use it.
type Borgmatic::Encryption = Enum[
  'none',
  'authenticated',
  'authenticated-blake2',
  'repokey',
  'repokey-blake2',
]
