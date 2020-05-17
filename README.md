# syslogger
[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://lazau.github.io/syslogger/)
[![GitHub release](https://img.shields.io/github/release/lazau/syslogger.svg)](https://github.com/lazau/syslogger/releases)
[![Build Status](https://travis-ci.org/lazau/syslogger.svg?branch=master)](https://travis-ci.org/lazau/syslogger)

# Syslogger - A Log::Backend that writes to syslog.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     syslogger:
       version: 0.1.0
       github: lazau/syslogger
   ```

2. Run `shards install`

## Usage

```crystal
require "log"
require "syslogger"

Log.setup_from_env(backend: Log::SyslogBackend.new)
```

### Thread Safety

Currently, Log::SyslogBackend only calls `openlog` once when the first Log::SyslogBackend is instantiated.
Subsequent instantiations of Log::SyslogBackend does not change the ident, facility, nor options field registered by
`openlog`.

In conclusion, multiple Log::SyslogBackend can be instantiated, but only the first instiantiation applies the specified
options.
Writes by any number of Log::SyslogBackends are always thread safe as specified by
[POSIX](https://pubs.opengroup.org/onlinepubs/000095399/functions/xsh_chap02_09.html#tag_02_09_01).

## Contributing

1. Fork it (<https://github.com/lazau/syslogger/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors & Acknowledgements

- [Laza Upatising](https://github.com/lazau) - creator and maintainer
- [Chris Huxtable](https://github.com/chris-huxtable) - author of
  [syslog.cr](https://github.com/chris-huxtable/syslog.cr), where major pieces of code originates (lib_c, enums).
