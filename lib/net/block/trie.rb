
# frozen_string_literal: true

module Net
  module Block
    # Organize IPv4 addresses into a binary tree
    #
    class Trie
      attr_reader :parent
      attr_reader :network
      attr_reader :left
      attr_reader :right

      def self.root
        new(nil, Address.from('0.0.0.0/0'))
      end

      def self.from(root, *addresses)
        new(nil, Address.from(root)).tap do |trie|
          addresses.flatten.each { |addr| trie.insert(addr) }
        end
      end

      def initialize(parent, network)
        @parent = parent
        @network = network
      end

      # Check if the node has a left-hand child, and if the child satasifes an
      # optional block condition
      #
      def left?
        if @left.nil? then false
        elsif block_given? then yield left
        else true
        end
      end

      # Check if the node has a right-hand child, and if the child satasifes an
      # optional block condition
      #
      def right?
        if @right.nil? then false
        elsif block_given? then yield right
        else true
        end
      end

      # Check if the node has any children that satasfy an optional block condition
      #
      def any?(&block)
        left?(&block) || right?(&block)
      end

      # Check if the node has both children that satasfy an optional block condition
      #
      def all?(&block)
        left?(&block) && right?(&block)
      end

      # Check if the node has exactly one child that satasifes an optional block
      # condition
      #
      def one?(&block)
        left?(&block) ^ right?(&block)
      end

      # Check if the node has no children
      #
      def empty?
        !any?
      end

      # Check if the node or any of its decendants have only one child
      #
      def sparse?
        return true if one?
        return false if empty?

        ## all? -> true
        left.sparse? || right.sparse?
      end

      # Evaluate a block for each of the node's decendants. The node itself is evaluated first,
      # followed by left and left's decendants, then right and right's decendants. Blocks can
      # raise `StopIteration` to stop traversing farther into the Trie
      #
      def each(&block)
        begin
          yield self
        rescue StopIteration
          return ## break
        end

        left.each(&block) if left?
        right.each(&block) if right?

        self
      end

      # Allow reduction operations to traverse the Trie. Blocks can raise
      # `StopIteration` to stop traversing farther into the Trie
      #
      # @yields collection, node
      #
      def collect(collection = [], &block)
        begin
          yield collection, self
        rescue StopIteration
          return ## break
        end

        left.collect(collection, &block) if left?
        right.collect(collection, &block) if right?

        collection
      end

      # Return the address of this node's unallocated child if only one child
      # is populated
      #
      def unallocated
        return network.left_child unless left?
        return network.right_child unless right?
      end

      # Hash an Address object into the correct Trie node
      #
      def insert(address)
        unless network.subnet?(address)
          raise ArgumentError, 'Cannot insert an address that is not a subnet of this node'
        end

        ## Already allocated. This is somewhat undefined.
        return if network == address

        ## Direct descendant. Don't let a new entry clobber an existing node.
        return @left ||= Trie.new(self, address) if network.left_child == address
        return @right ||= Trie.new(self, address) if network.right_child == address

        if network.left_child.subnet?(address)
          @left ||= Trie.new(self, network.left_child)
          left.insert(address)
        elsif network.right_child.subnet?(address)
          @right ||= Trie.new(self, network.right_child)
          right.insert(address)
        end
      end

      # Find the least-specific prefix for continuous blocks of hashed IPv4 addresses
      #
      def aggregate
        ## Find nodes in the trie whose offspring from complete sets. e.g. every
        ## node that has two children, or zero children, recursively. Nodes with
        ## one child can not be aggregated without covering a hole
        collect do |aggregates, node|
          next if node.sparse?

          aggregates << node
          raise StopIteration
        end
      end

      # Find unallocated prefixes in a set of IPv4 addresses
      #
      def holes
        collect do |unallocated, node|
          ## This children and all of this node are non-sparse
          raise StopIteration unless node.sparse?

          ## If this node is missing a child, collect that address. In any case,
          ## keep searching this node's decendants for unallocated children
          unallocated << node.unallocated unless node.all?
        end
      end

      # Find possible addresses for a given mask length
      #
      def next(length)
        ## Select blocks with short ehough masks
        suitable = holes.select { |address| address.length <= length }.sort

        ## Find the first subnet of each available block that satasifes the given length
        suitable.map do |address|
          address = address.left_child until address.length == length
          address
        end
      end

      # Flatten the Trie into an array of its hashed network Address instances
      #
      def flatten
        return [network] if empty?

        children = []
        children += left.flatten if left?
        children += right.flatten if right?

        children
      end

      def to_s(indent = 0)
        lines = [(' ' * indent) + network.to_s]
        lines << left.to_s(indent + 2) if left?
        lines << right.to_s(indent + 2) if right?

        lines.join("\n")
      end
    end
  end
end
