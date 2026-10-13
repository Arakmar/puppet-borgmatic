# @summary An octal umask
#
# It is a string so that its leading zero survives: Puppet reads an integer
# literal such as `0027` as an octal number.
#
# @example
#   '0027'
type Borgmatic::Umask = Pattern[/\A0?[0-7]{3}\z/]
