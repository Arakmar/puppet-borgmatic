# @summary A command hook of a borgmatic configuration (borgmatic >= 2.0)
#
# @example Dump a database before each backup
#   { 'before' => 'action', 'when' => ['create'], 'run' => ['/usr/local/bin/dump-db'] }
# @example Report failures
#   { 'after' => 'error', 'run' => ['echo "{configuration_filename}: {error}" | mail root'] }
type Borgmatic::Command = Variant[
  Struct[{
      'before'         => Enum['action', 'repository', 'configuration', 'everything'],
      Optional['when'] => Array[Borgmatic::Action, 1],
      'run'            => Array[String[1], 1],
  }],
  Struct[{
      'after'            => Enum['action', 'repository', 'configuration', 'everything', 'error'],
      Optional['when']   => Array[Borgmatic::Action, 1],
      Optional['states'] => Array[Enum['finish', 'fail'], 1],
      'run'              => Array[String[1], 1],
  }],
]
