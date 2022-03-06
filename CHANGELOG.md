# Changelog

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
