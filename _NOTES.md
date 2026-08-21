# Notes from test suite modernization (2026-08-20)

Findings from modernizing this bundle's test suites

## Result

All suites 100% passing under Ruby 4.0.6, runnable from any working directory, individually or all at once via `rake` from the bundle root:

```sh
rake                                    # 27 tests, 194 assertions
ruby Support/test/test_rails_path.rb    # 17 tests, 105 assertions
ruby Support/test/test_buffer.rb        #  5 tests,  26 assertions
ruby Support/test/test_generator.rb     #  5 tests,  63 assertions
```

## What was broken and since when

**The headline: the mock's guard was disabled by Ruby 1.9 and the mock stomped the real code.** `text_mate_mock.rb` is designed to redirect `TextMate.env` from environment variables to class variables and to add plain accessors only for variables the real `rails/text_mate.rb` does not already wrap. The guard was `TextMate.methods.include?(key.to_s)`. `Object#methods` returned Strings in Ruby 1.8 and Symbols since 1.9, so the guard has been always-false since 2007. The mock therefore overrode the real wrappers, including `line_number`, which the real module converts to a 0-based Integer. `Buffer#find` then compared a raw String against an Integer and raised. This single broken guard accounted for all five `test_buffer` errors and all five `test_rails_path` failures. The fix is `TextMate.respond_to?(key)`.

**The fixture Rails 2 application cannot boot on modern Ruby.** `test_generator` shells out to the fixture app's `script/generate`, whose `config/boot.rb` reads `Gem::RubyGemsVersion`, removed from RubyGems long ago. Resurrecting Rails 2 boot is not this bundle's contract. The `Generator` library only parses the printed output, and the expected Rails 2.3 format is documented in a comment in `Support/lib/rails/generate.rb`. The fixture script is now a canned-transcript fake printing that documented format, the same pattern as ruby.tmbundle's fake rvm and rbenv fixtures.

**`rake test` has run zero tests since May 2008.** Commit `5055740` renamed every `*_test.rb` to `test_*.rb` for autotest compatibility but never updated the Rakefile's `Support/test/*_test.rb` pattern, so the rake task silently matched nothing for eighteen years. The pattern is now `test_*.rb` and `rake` runs everything.

**The usual CWD trapping.** `require File.dirname(__FILE__) + '/test_helper'` and relative-leaning load path pushes only resolved from `Support/test/`. Now `require_relative` and `__dir__`-anchored paths.

## Fossils and observations (untouched)

- `test_text_mate.rb` is a one-line file, just the helper require, with no test class. It was already a one-line stub before the 2008 rename. It marks never-written coverage for `rails/text_mate.rb`. Left in place.
- The mock's accessor generation uses `eval` string interpolation three times over. Live, exercised, left alone.
- This quest pins the fixture to the Rails 2.3 `script/generate` output format. Modern Rails uses `bin/rails generate` with different output, and the bundle's `Generator` library does not support it. Supporting modern Rails projects is feature work for a separate decision, not test modernization.
- The Phase 3 change from `URI.escape` to `URI::DEFAULT_PARSER.escape` in `rails/text_mate.rb` sits on the `TextMate.open` code path, which these suites do not reach. Still unexecuted by any test.
