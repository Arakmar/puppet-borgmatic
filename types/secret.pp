# @summary A secret such as a passphrase or a password, optionally Sensitive
type Borgmatic::Secret = Variant[String, Sensitive[String]]
