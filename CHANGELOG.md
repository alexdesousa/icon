# Changelog

## v0.2.4

### Changes

  * [Bugfix] Sometimes blocks contain non-standard transaction failure reason
    and made schema decoding fail.
  * [Bugfix] When messages are coming too fast, the messages overflowing the
    subscriber are height messages. Now the actual messages are immediately
    sent to subscribers.

## v0.2.3

### Changes

  * [Bugfix] Sometimes the subscriber could hang and not publish any messages
    because it was ensuring order. This lead to slow synchronizations. Now the
    messages are not guaranteed to arrive in order, but the event logs now
    include the height, so it's easier for the subscriber to pick the order
    from that.

## v0.2.2

### Changes

  * [Bugfix] When events were coming too fast, the subscriber was drowned in
    messages and could never publish the messages.

## v0.2.1

### Changes

  * [Bugfix] Yggdrasil channels with source as event were ignoring the current
    height when reconnecting.

## v0.2.0

### Changes

  * [Bugfix] Fixed bug where Yggdrasil events where arriving out of order.
  * [Enhancement] Now subscribing to events returns the tick of the block where
    the event occurred.

## v0.1.8

### Changes

  * [Bugfix] Bad return value when reinitializing the icon subscriber.

## v0.1.7

### Changes

  * [Enhancement] Changed websocket reconnection message from `:timeout` to
    `:re_init` for better understanding of what's happening.
  * [Enhancement] Positive integer type.
  * [Bugfix] Now integers can be negative.
  * [Bugfix] Fixed a race condition bug where multiple backoff messages were
    issued.

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
