# frozen_string_literal: true

require 'forwardable'
require_relative 'bit'

module Net
  module Block
    # A vector of Bit objects
    #
    class BitSet
      include Enumerable
      extend Forwardable

      def_delegators :bits, :[], :length

      # Populate a BitSet from an Integer value
      #
      def self.from(value, length)
        value = value.to_i

        result = new
        length.times do
          result.push(Bit.from(value % 2))
          value /= 2 # Ruby Integer division rounds down
        end

        result
      end

      # Populate a BitSet for a bit-mask
      #
      def self.mask(ones, length)
        raise RangeError, 'Mask cannot have more ones that the BitSet length' if ones > length

        result = new(length)

        until result.ones == ones
          length -= 1
          result.flip!(length)
        end

        result
      end

      def initialize(length = 0, fill = Zero)
        @bits = Array.new(length, fill)
      end

      # Flip a bit at `index` in-place in the BitSet
      #
      def flip!(index)
        bits[index] = !bits[index]

        self
      end

      def !
        BitSet.new.tap { |result| each { |bit| result.push(!bit) } }
      end

      def &(other)
        raise IndexError, 'BitSets must be the same length' unless other.length == length
        BitSet.new.tap { |result| each_with_index { |bit, i| result.push(bit & other[i]) } }
      end

      def |(other)
        raise IndexError, 'BitSets must be the same length' unless other.length == length
        BitSet.new.tap { |result| each_with_index { |bit, i| result.push(bit | other[i]) } }
      end

      def ==(other)
        other.length == length && other.bits == bits
      end

      def <=>(other)
        raise IndexError, 'BitSets must be the same length' unless other.length == length

        ## Comparison searches from MSB (31 for an IPV4) to LSB for the first
        ## pair of bits that do not match, and returns that comparison
        index = length - 1
        index -= 1 until bits[index] != other.bits[index] || index.zero?

        other.bits[index] <=> bits[index]
      end

      # Join two BitSets into a new BitSet
      def +(other)
        BitSet.new.tap { |result| result.bits = bits + other.bits }
      end

      def clone
        BitSet.new.tap { |result| result.bits = bits.clone }
      end

      # Construct a BitSet from a sub-section of this BitSet. `from` is inclusive,
      # `to` is exclusive.
      #
      def slice(from, to)
        raise ArgumentError, 'Argument `from` must be less than or equal to `to`' unless from <= to
        raise ArgumentError, 'Argument `from` must be between 0 and the set length' unless from.between?(0, length)
        raise ArgumentError, 'Argument `to` must be between 0 and the set length' unless from.between?(0, length)

        BitSet.new(to - from).tap { |set| set.bits = bits.slice(from, to - from) }
      end

      def ones
        count(&:one?)
      end

      def zeros
        count(&:zero?)
      end

      # Calculate the Integer value of the BitSet
      def to_i
        reduce([0, 0]) { |(value, index), bit| [value + bit**index, index + 1] }.first
      end

      def to_s
        "<#{self.class.name}(#{length}): #{reverse.join(' ')}>"
      end

      # Helper to format the BitSet as a dotted-quad IPv4 address string
      #
      def v4
        raise RangeError, 'BitSet must have a length of 32 to format as an IPv4 address!' unless length == 32
        [slice(24, 32), slice(16, 24), slice(8, 16), slice(0, 8)].map(&:to_i).join('.')
      end

      protected

      # Allow a BitSet to modify the underlying bit-array of another BitSet
      #
      attr_reader :bits
      attr_writer :bits

      def_delegators :bits, :each, :push, :reverse, :unshift
    end
  end
end
