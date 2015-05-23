require 'queque/version'
require 'redis-objects'
require 'monitor'


# Queque is a Redis-backed, thread-safe queue
#
# @author hololeap
class Queque
  include MonitorMixin
  
  DEFAULT_LIST_NAME = 'queque'

  # @!method bake(list_name = nil)
  #   An alias for new()
  #   @param list_name [String] the name of the behind-the-scenes Redis list
  #   @!scope class
  singleton_class.class_eval { alias_method :bake, :new }

  # @!attribute [r] list
  #   @return [Redis::List] the behind-the-scenes Redis list
  attr_reader :list

  # If no name is given, an unused one will be chosen automatically
  #
  # @param list_name [String] the name of the behind-the-scenes Redis list
  def initialize(list_name = nil)

    @empty_cond = new_cond
    @list_name = 
      if list_name
        r = Redis.current
        if r.exists(list_name) and (t = r.type(list_name)) != 'list'
          raise "Redis object exists and is not a list: #{list_name} (#{t})"
        end
        list_name
      else
        next_list_name
      end
    
    setup_list
    
    super()
  end

  # @return [String] the name of the behind-the-scenes Redis list
  def name
    @list_name
  end

  # Add objects to the end of the queue
  #
  # @note Limited to objects that can used by {Marshal}
  # @param objs [Object] 1+ objects to add to queue
  # @return self
  def push(*objs)
    write_operation { @list.push(*objs) }
  end
  
  alias_method :<<, :push
  alias_method :enq, :push

  # Add objects to beginning of queue
  #
  # @note (see #push)
  # @param (see #push)
  # @return (see #push)
  def unshift(*objs)
    write_operation { @list.unshift(*objs) }
  end

  # Remove the last object from the list
  #
  # @note If the queue is empty, the calling thread will be blocked until new
  #   data is added. If a true value is passed to the method, an {ArgumentError} will
  #   be raised instead.
  # @param non_block [Boolean] if true, will raise an exception if the queue is empty
  # @return [Object] the removed object
  def pop(non_block = false)
    read_operation(non_block) { @list.pop }
  end
  
  alias_method :deq, :pop

  # Remove the first object from the list
  #
  # @note (see #pop)
  # @param (see #pop)
  # @return (see #pop)
  def shift(non_block = false)
    read_operation(non_block) { @list.shift }
  end

  # @return [Boolean] is the queue empty?
  def empty?
    synchronize { @list.empty? }
  end

  # @return [Integer] number of objects in the queue
  def length
    synchronize { @list.size }
  end
  
  alias_method :size, :length

  # Removes all data from the queue
  def clear!
    Redis.current.del(@list_name)
    setup_list
  end
  
  private

  # Finds the next, unused name to be used for the Redis list
  #
  # @return [String] unused Redis list name
  def next_list_name
    list_regexp = /^#{DEFAULT_LIST_NAME}_(\d+)/
    
    last_num = Redis.current.keys('*').grep(list_regexp)
                 .map {|n| n[list_regexp, 1].to_i }.sort.last || 0
    
    "#{DEFAULT_LIST_NAME}_#{last_num + 1}"
  end

  # Used for read operations that need to be synchronized
  #
  # @yield Operation that needs to be synchronized
  # @return [Object] the return of the yielded block
  def read_operation(non_block)
    raise ArgumentError, 'no block given' unless block_given?
    
    synchronize do
      raise ThreadError, 'queque empty' if non_block and empty?
      @empty_cond.wait_while { empty? }
      
      yield
    end
  end

  # Used for write operations that need to be synchronized
  #
  # @yield (see #read_operation)
  # @return self
  def write_operation
    raise ArgumentError, 'no block given' unless block_given?
    
    synchronize do
      yield
      @empty_cond.signal
      self
    end
  end

  # Create the list from @list_name
  def setup_list
    @list = Redis::List.new(@list_name, marshal: true)
  end

end
