# frozen_string_literal: true

module Net
  module Block
    # A boolean value
    #
    class Bit
      PLUS  = 1
      ZERO  = 0
      MINUS = -1

      class << self
        # Coerce a value to a Bit
        #
        # NOTE that `to_i` is called on `value`, and may have unexpected effects
        # upon non-numeric values.
        #
        def from(value)
          return value if value.is_a?(self)
          value.to_i.zero? ? Zero : One
        end

        def ^(other)
          other == self ? Zero : One
        end

        def one?
          false
        end

        def zero?
          false
        end

        def to_s
          to_i.to_s
        end
      end
    end

    # A One Bit
    #
    class One < Bit
      class << self
        def !
          Zero
        end

        def &(other)
          other
        end

        def |(_other)
          One
        end

        def <=>(other)
          other == self ? Bit::ZERO : Bit::MINUS
        end

        # Calculate the binary power of the bit at a given position in a BitSet
        #
        def **(other)
          Bit::PLUS << other
        end

        def one?
          true
        end

        def to_i
          Bit::PLUS
        end
      end
    end

    # A Zero Bit
    #
    class Zero < Bit
      class << self
        def !
          One
        end

        def &(_other)
          Zero
        end

        def |(other)
          other
        end

        def <=>(other)
          other == self ? Bit::ZERO : Bit::PLUS
        end

        def **(_other)
          Bit::ZERO
        end

        def zero?
          true
        end

        def to_i
          Bit::ZERO
        end
      end
    end
  end
end
