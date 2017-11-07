Net::Block
==========

The `net-block` gem provides several foundational classes for managing information about IPv4 networks and addresses, including a BitSet, Address, and Trie.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'net-block'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install net-block

## Usage

The included `nb` CLI exposes several commands to summarize a given network specification. Networks are defined in YAML documents with the following layout:

```yml
root: 192.168.1.0/24
subnets:
- address: 192.168.1.0/27
  property1: value1
- address: 192.168.1.32/27
  property1: value2
- address: 192.168.1.64/27
  property1: value3
```

A `root` address in CIDR form that encapsulates all of the given subnets must be provided. The `subnets` property is an array of objects with, at least, an `address` property containing a CIDR string. Additional properties may be provided for metadata.

Run `bundle exec nb help` for detailed CLI usage.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jmanero/net-block.
