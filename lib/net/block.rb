# frozen_string_literal: true

require_relative 'block/address'
require_relative 'block/bit'
require_relative 'block/bitset'
require_relative 'block/trie'

require_relative 'block/cli'

module Net
  # Organize and manipulate IPv4 addresses and network blocks
  #
  module Block
    class << self
      # Build an Address object from a CIDR string
      #
      def address(cidr, **metadata)
        Address.from(cidr, **metadata)
      end

      # Construct a new Trie structure with the given root network and subnets
      #
      def trie(root, *addresses)
        Trie.from(root, *addresses)
      end
    end
  end
end
