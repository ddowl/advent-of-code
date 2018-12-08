# We're basically constructing a graph of requirements and then performing a topological sort on it
# (https://en.wikipedia.org/wiki/Topological_sorting) in order to find an ordering that satisfies the requirements
# described by the graph.

class Graph

  # An adjacency list is a way to represent a graph
  # It consists of a mapping of all vertices in the graph to a list of vertices that they point to
  def initialize(edges)
    @adjacency_list = Hash.new { |h, k| h[k] = [] }
    edges.each do |edge|
      @adjacency_list[edge[0]] << edge[1]
    end
    @adjacency_list.transform_values!(&:uniq)
    p @adjacency_list
  end

  def indegree(vertex)
    @adjacency_list.map do |_, out_vs|
      out_vs.count(vertex)
    end.sum
  end

  def vertex_indegrees
    non_zero_indegrees = @adjacency_list.values.flatten.group_by(&:itself).transform_values(&:size)
    zero_indegrees = (@adjacency_list.keys - non_zero_indegrees.keys).map { |v| [v, 0] }.to_h
    non_zero_indegrees.merge(zero_indegrees)
  end

  def topo_sort
    # Find all verticies with in-degree of 0
    # Those "have no prereqs" and we can start processing them immediately
    indegrees = vertex_indegrees
    vs_with_no_incoming_edges = indegrees.keys
                                  .select { |vertex| indegrees[vertex].zero? }
                                  .sort
                                  .reverse
    processed_vertices = []
    until vs_with_no_incoming_edges.empty?
      free_vertex = vs_with_no_incoming_edges.pop
      indegrees.delete(free_vertex)
      processed_vertices.push(free_vertex)

      # The spec states:
      # "If more than one step is ready, choose the step which is first alphabetically."
      @adjacency_list[free_vertex].sort.reverse.each do |v|
        indegrees[v] -= 1
        raise if indegrees[v] < 0

        vs_with_no_incoming_edges << v if indegrees[v].zero?
      end
    end
    processed_vertices.join
  end

  def topo_sort_parallel_steps(workers, additional_task_latency)
    indegrees = vertex_indegrees
    vs_with_no_incoming_edges = indegrees.keys
                                  .select { |vertex| indegrees[vertex].zero? }
                                  .map { |v| [v, task_latency(v) + additional_task_latency] }
                                  .sort_by { |_, l| l }
                                  .reverse
    processed_vertices = []
    num_steps = 0

    # A worker can only work on one particular task at a time.
    # We'll use this to only decrement tasks that are being worked on
    worker_queue = update_worker_queue(vs_with_no_incoming_edges, [], workers)
    vs_with_no_incoming_edges = decrement_assigned_tasks(vs_with_no_incoming_edges, worker_queue)

    until vs_with_no_incoming_edges.empty?
      # puts "step: #{num_steps}"
      # puts "vs_with_no_incoming_edges: #{vs_with_no_incoming_edges}"
      # puts "worker_queue: #{worker_queue}"
      num_steps += 1

      while !vs_with_no_incoming_edges.empty? && vs_with_no_incoming_edges.last[1] <= 0
        free_vertex = vs_with_no_incoming_edges.pop[0]
        indegrees.delete(free_vertex)
        worker_queue.delete(free_vertex)
        processed_vertices.push(free_vertex)

        # The spec states:
        # "If more than one step is ready, choose the step which is first alphabetically."
        @adjacency_list[free_vertex].sort.reverse.each do |v|
          indegrees[v] -= 1
          raise if indegrees[v] < 0

          vs_with_no_incoming_edges << [v, task_latency(v) + additional_task_latency] if indegrees[v].zero?
        end
      end

      worker_queue = update_worker_queue(vs_with_no_incoming_edges, worker_queue, workers)
      vs_with_no_incoming_edges = decrement_assigned_tasks(vs_with_no_incoming_edges, worker_queue)
    end
    num_steps
  end

  private

  def task_latency(v)
    v.ord - 'A'.ord + 1
  end

  def update_worker_queue(vs, worker_queue, workers)
    # if there's any space in the worker queue, let's add some tasks to it
    unassigned_tasks = vs.map(&:first) - worker_queue
    until worker_queue.size == workers || unassigned_tasks.empty?
      worker_queue << unassigned_tasks.pop
    end
    worker_queue
  end

  def decrement_assigned_tasks(vs, worker_queue)
    vs.map do |vertex, seconds_left_to_process|
      raise if seconds_left_to_process.zero?

      if worker_queue.include?(vertex)
        [vertex, seconds_left_to_process - 1]
      else
        [vertex, seconds_left_to_process]
      end
    end.sort_by { |_, l| l }.reverse
  end
end

edges = File.readlines('input.txt').map { |line| line.scan(/Step (.) .* step (.)/).first }
p edges
graph = Graph.new(edges)
topo_ordering = graph.topo_sort
p topo_ordering
steps_to_perform_parallel_topo_sort = graph.topo_sort_parallel_steps(5, 60)
p steps_to_perform_parallel_topo_sort

puts
