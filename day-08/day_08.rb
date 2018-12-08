class TreeNode
  attr_reader :children, :metadata

  def initialize
    @children = []
    @metadata = []
  end

  def add_child(node)
    children << node
  end

  def add_metadata(num)
    metadata << num
  end

  def sum_subtree_metadata
    metadata.sum + children.map(&:sum_subtree_metadata).sum
  end

  def value
    return metadata.sum if children.empty?

    metadata
      .map { |num| num - 1 }
      .select { |idx| idx >= 0 && idx < @children.size }
      .map { |idx| children[idx].value }
      .sum
  end
end

class Tree

  def initialize(tree_seq)
    @root, _ = build_tree(tree_seq, 0)
  end

  def sum_metadata
    @root.sum_subtree_metadata
  end

  def value
    @root.value
  end

  private

  def build_tree(tree_seq, curr_idx)
    return nil if curr_idx >= tree_seq.length

    # All nodes will 2 space-separated integers specifying the number of children they
    # have and the number of metadata integers they hold
    num_children = tree_seq[curr_idx]
    num_metadata = tree_seq[curr_idx + 1]
    curr_node = TreeNode.new

    # In order to finish constructing this node, we'll need serially construct our children.
    # The index returned will be the start of this node's metadata
    next_idx = curr_idx + 2
    num_children.times do
      child_node, next_idx = build_tree(tree_seq, next_idx)
      curr_node.add_child(child_node)
    end

    # now our index is in a position to grab the metadata for this node
    num_metadata.times do
      curr_node.add_metadata(tree_seq[next_idx])
      next_idx += 1
    end

    [curr_node, next_idx]
  end
end

raw_tree_seq = File.read('input.txt').split(' ').map(&:to_i)

p raw_tree_seq

tree = Tree.new(raw_tree_seq)
p tree
puts tree.sum_metadata
puts tree.value

puts