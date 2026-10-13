# @summary Free-form settings of a borgmatic hook
#
# Used for the database, monitoring and snapshot hooks, whose many and
# evolving keys are checked by borgmatic itself. Top-level values may be
# Sensitive, for example a password.
type Borgmatic::Settings = Hash[String[1], Variant[Data, Sensitive]]
