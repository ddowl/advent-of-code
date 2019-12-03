require 'time'

class Duration
  def self.minute_diff(time_a, time_b)
    (time_b - time_a) / 60
  end
end

# Sometimes guards start shift before midnight, but all shifts finish before 1:00am
# Each shift is exactly an hour long
class Shift
  attr_reader :guard_id, :start_time, :asleep_ranges

  def initialize(guard_id, start_time)
    @guard_id = guard_id
    @start_time = start_time
    @is_awake = true # for sanity checking methods are called in the right order
    @asleep_ranges = [] # Guard will always start awake, then fall asleep, then wake up, then fall asleep, etc.
    @asleep_start_time = nil
  end

  def falls_asleep(at)
    raise "guard #{guard_id} can't fall asleep twice!" unless @is_awake

    @is_awake = false
    @asleep_start_time = at
  end

  def wakes_up(at)
    raise "guard #{guard_id} can't wake up twice!" if @is_awake

    @is_awake = true
    @asleep_ranges << (@asleep_start_time...at)
  end

  def minutes_asleep
    @asleep_ranges.map do |range|
      doze_off_min = Duration.minute_diff(@start_time, range.begin).to_i
      woke_up_min = Duration.minute_diff(@start_time, range.end).to_i
      woke_up_min - doze_off_min
    end.sum
  end

  # I'd like to use @asleep_ranges here in a class method,
  # but I'm not sure if I should make it public.
  # Returns [most_slept_minute, num_times_slept], or nil if guard never slept during any shift
  def self.most_slept_minute(shifts)
    # p shifts
    minutes = shifts.map do |shift|
      shift.asleep_ranges.map do |range|
        # Why can't we enumerate a range of Time's by minutes?
        curr_time = range.begin
        end_time = range.end
        step_by_minutes = []
        while curr_time < end_time
          step_by_minutes.push(curr_time)
          curr_time += 60
        end
        step_by_minutes.map(&:min) # minute of hour from Time obj
      end
    end
    minutes
      .flatten
      .group_by(&:itself)
      .transform_values(&:size)
      .max_by { |_, v| v }
  end
end

class ShiftLog
  def initialize
    @shifts = []
    @date_to_shift = {}
  end

  def add_shift(guard_id, time)
    shift = Shift.new(guard_id, time)
    @date_to_shift[time.to_date] = shift
    @shifts << shift
  end

  def get_shift(time)
    shift = @date_to_shift[time.to_date]
    shift = @date_to_shift[time.to_date - 1] if shift.nil?
    shift
  end

  def shifts_per_guard
    @shifts.group_by(&:guard_id)
  end
end


log = ShiftLog.new
File.readlines('input.txt').sort.each do |line|
  time_str = line.scan(/\[(.*)\]/).first.first
  time = Time.parse(time_str)
  if line.include?('begins shift')
    guard_id = line.scan(/#(\d+)/).first.first.to_i
    log.add_shift(guard_id, time)
  elsif line.include?('falls asleep')
    log.get_shift(time).falls_asleep(time)
  elsif line.include?('wakes up')
    log.get_shift(time).wakes_up(time)
  else
    raise Error("unexpected input detected: #{line}")
  end
end

guards = log.shifts_per_guard

# Part 1
sleepiest_guard = guards
                    .transform_values { |shifts| shifts.map(&:minutes_asleep).sum }
                    .max_by { |_, v| v }

sleepiest_guard_id = sleepiest_guard.first
sleepiest_minute = Shift.most_slept_minute(guards[sleepiest_guard_id]).first

puts "sleepiest guard: #{sleepiest_guard_id}"
puts "sleepiest minute: #{sleepiest_minute}"
puts "their product: #{sleepiest_guard_id * sleepiest_minute}"
puts

# Part 2
sleepiest_guard_on_minute = guards
                              .transform_values do |shifts|
                                min = Shift.most_slept_minute(shifts)
                                min.nil? ? nil : min[1]
                              end
                              .reject { |_, m| m.nil? }
                              .max_by { |_, v| v }

sleepiest_guard_on_minute_id = sleepiest_guard_on_minute.first
sleepiest_minute = Shift.most_slept_minute(guards[sleepiest_guard_on_minute_id]).first

puts "sleepiest guard on a given minute: #{sleepiest_guard_on_minute_id}"
puts "sleepiest minute: #{sleepiest_minute}"
puts "their product: #{sleepiest_guard_on_minute_id * sleepiest_minute}"
puts
