# Changelog

## v0.1.7

### Changes

  * [Enhancement] Changed websocket reconnection message from `:timeout` to
    `:re_init` for better understanding of what's happening.

## v0.1.6

### Changes

  * [Enhancement] Added exponential backoff to the websocket reconnection
    retries.
  * [Enhancement] Added the possibility of configuring the node URLs from
    environment variables or Elixir configuration to override the defaults.
  * [Enhancement] Improved websocket test code coverage.
  * [Enhancement] The websocket now reconnects to the last know height when
    height is available and being updated.

## v0.1.5

### Changes

  * [Typo] Fixed misleading exception message in ICON's Yggdrasil subscriber
    when process crashes.

## v0.1.4

### Changes

  * [Bugfix] Event logs weren't pulled correctly when the schema type
    encountered a `nil` value.

## v0.1.3

### Changes

  * [Enhancement] Added ICON 2.0 adapter for Yggdrasil.

## v0.1.2

### Changes

  * [Bugfix] `Icon.call/5` didn't load the results into schema structs though they were
    specified in the `response_schema` option.
  * [Enhancement] Added variable keys for schemas, giving more freedom when
    casting dictionaries.

## v0.1.1

### Changes

  * Improved documentation.

## v0.1.0

### Changes

  * First SDK API inspired by [ICON Python's SDK](https://github.com/icon-project/icon-sdk-python).
