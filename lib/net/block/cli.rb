# frozen_string_literal: true

require 'thor'
require 'yaml'

require_relative '../block'

module Net
  module Block
    # CLI for nb executable
    #
    class CLI < Thor
      desc 'sumarize NETWORK', 'Read a network allocation table from a YAML file and sumarize'
      def summarize(path)
        trie = Utils.load_trie(path)

        ## Aggregations
        aggregates = trie.aggregate
        holes = trie.holes

        say "Found #{aggregates.length} continuous netblocks:"
        aggregates.each { |block| puts " - #{block.network}" }
        puts '---'
        puts ''

        say "Found #{holes.length} unallocated netblocks:"
        holes.sort_by(&:length).each { |address| puts " - #{address}" }
      end

      desc 'aggregate NETWORK', 'Read a network allocation table from a\
 YAML file aggregate into the largest possible network blocks'

      def aggregate(path)
        aggregates = Utils.load_trie(path).aggregate

        say "Found #{aggregates.length} continuous netblocks:"
        aggregates.each { |block| puts "---\n#{block}" }
      end

      desc 'next NETWORK MASK', 'Find the next available address of the given\
 MASK length in the network allocation table'
      def next(path, length)
        suitable = Utils.load_trie(path).next(length.to_i)

        say "Found #{suitable.length} possible addresses:"
        suitable.each { |address| puts " - #{address}" }
      end
    end

    # Common CLI helper methods
    #
    module Utils
      class << self
        def load_yaml(path)
          content = IO.read(File.expand_path(path))
          YAML.safe_load(content)
        end

        def load_trie(path)
          network = load_yaml(path)

          ## Parse subnet entries {address: 'CIDR/NN', ...metadata: tags}
          addresses = network.fetch('subnets').map do |entry|
            cidr = entry.delete('address')
            metadata = entry.each_with_object({}) { |(k, v), object| object[k.to_sym] = v }

            Address.from(cidr, **metadata)
          end

          ## Build the Trie
          Trie.from(network.fetch('root'), addresses)
        end
      end
    end
  end
end
