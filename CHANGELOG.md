# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.2 - 2024-12-19

### Added
* Enhanced test infrastructure with cross-version compatibility testing
* New `bin/rspec_all` script for testing across multiple Ruby and Pagy versions
* Support for testing with Ruby 2.7.8, 3.1.2, 3.2.2, and 3.3.5
* Support for testing with Pagy versions 5, 6, 7, 8, and 9
* Command-line options for targeted testing:
  * `./bin/rspec_all` - Run all compatible combinations
  * `./bin/rspec_all <ruby_version>` - Test specific Ruby version with all compatible Pagy versions
  * `./bin/rspec_all <ruby_version> <pagy_version>` - Test specific combination
* Help system with `--help` and `-h` flags
* Comprehensive error handling with helpful error messages

### Changed
* Improved test reliability by using compatibility matrix instead of testing all combinations
* Optimized test execution time by filtering out known incompatible version combinations
* Enhanced developer experience with better test output and error messages

### Technical Details
* Ruby 2.7.x: Compatible with Pagy 5, 6
* Ruby 3.1.x: Compatible with Pagy 7
* Ruby 3.2.x: Compatible with Pagy 7, 8, 9
* Ruby 3.3.x: Compatible with Pagy 9

## 0.0.1 - 2023-11-14
The first release of the esse-pagy plugin. This release includes the following features:
* Add `pagy_search` method to the `Esse::Index` class.
* Add `pagy_search` method to the `Esse::Cluster` class.
* Add `pagy_esse` method to the `Pagy` class.
* Add `pagy_esse` method to the `Pagy::Backend` class.
