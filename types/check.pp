# @summary A consistency check of a borgmatic configuration
#
# A string is the name of the check, the other keys are those of the
# `checks` option of borgmatic.
#
# @example
#   'repository'
#   { 'name' => 'repository', 'frequency' => '2 weeks', 'only_run_on' => ['Saturday'] }
type Borgmatic::Check = Variant[
  Enum['repository', 'archives', 'data', 'extract', 'spot', 'disabled'],
  Struct[{
      'name'                                 => Enum['repository', 'archives', 'data', 'extract', 'spot', 'disabled'],
      Optional['frequency']                  => String[1],
      Optional['only_run_on']                => Array[String[1], 1],
      Optional['max_duration']               => Integer[1],
      Optional['count_tolerance_percentage'] => Numeric,
      Optional['data_sample_percentage']     => Numeric,
      Optional['data_tolerance_percentage']  => Numeric,
      Optional['xxh64sum_command']           => String[1],
  }],
]
