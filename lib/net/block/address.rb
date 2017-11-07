# frozen_string_literal: true

require_relative 'bitset'

module Net
  module Block
    # An IPv4 network address
    #
    class Address
      ZERO = 0
      THIRTY_ONE = 31
      THIRTY_TWO = 32

      attr_reader :address
      attr_reader :mask
      attr_reader :metadata

      # Construct an Address from a CIDR string
      #
      def self.from(string, **metadata)
        dotted, mask_length = string.split('/')
        octets = dotted.split('.').map(&:to_i)

        mask_length ||= THIRTY_TWO # If argument didn't have a /MASK, default to /32
        mask_length = mask_length.to_i

        ## IPv4 Validation
        unless mask_length.between?(ZERO, THIRTY_TWO)
          raise ArgumentError, "Mask length `#{mask}` is not valid for an IPv4 address"
        end

        unless octets.length == 4 && octets.all? { |o| o.between?(ZERO, 255) }
          raise ArgumentError, "Address `#{dotted}` is not a valid IPv4 address in dotted-decimal form"
        end

        ## Generate BitSet from address octets. BitSets are little-endian!
        address = octets.map { |octet| BitSet.from(octet, 8) }.reverse.reduce(:+)

        new(address, BitSet.mask(mask_length, THIRTY_TWO), **metadata)
      end

      def initialize(address, mask, **metadata)
        @address = address
        @mask = mask
        @metadata = metadata
      end

      def network
        Address.new(mask & address, mask.clone)
      end

      def broadcast
        Address.new(address | !mask, mask.clone)
      end

      # If this is a network address, ANDing w/ mask should be a NOOP
      #
      def network?
        (address & mask) == address
      end

      # Test if a given address is a sub-network of this address
      #
      def subnet?(other)
        return false if other.length <= length

        (mask & other.address) == address
      end

      # Calculate the super-block of this address. For a host-address, this is
      # the network address. For a network-address, this is the next-shortest mask
      #
      def parent
        return network unless network?
        return @parent unless @parent.nil?

        ## Calculate the next shortest prefix
        supermask = mask.clone
        supermask.flip!(THIRTY_TWO - length)

        @parent = Address.new(supermask & address, supermask)
      end

      # Calculate the bottom subnet of the next most specific prefix
      #
      def left_child
        raise RangeError, 'Cannot allocate an address with mask longer than 32' if length == THIRTY_TWO
        return @left_child unless @left_child.nil?

        ## Calculate the next longest prefix
        submask = mask.clone
        submask.flip!(THIRTY_ONE - length)

        @left_child = Address.new(network.address.clone, submask)
      end

      # Calculate the top subnet of the next most specific prefix
      #
      def right_child
        raise RangeError, 'Cannot allocate an address with mask longer than 32' if length == THIRTY_TWO
        return @right_child unless @right_child.nil?

        ## Calculate the next longest prefix
        submask = mask.clone
        submask.flip!(THIRTY_ONE - length)

        ## Increment next-most-significant bit in network address. Should always be Zero
        ## for the `network` Address instance.
        subnet = network.address.clone
        subnet.flip!(THIRTY_ONE - length)

        @right_child = Address.new(subnet, submask)
      end

      def length
        mask.ones
      end

      def ==(other)
        length == other.length && address == other.address
      end

      def <=>(other)
        address <=> other.address
      end

      def to_s
        annotations = metadata.map { |k, v| "#{k}: #{v}" }.join(', ')

        "#{address.v4}/#{mask.ones} #{annotations}"
      end
    end
  end
end
