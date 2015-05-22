require 'queque/version'
require 'redis-objects'
require 'monitor'

class Queque
  include MonitorMixin
  
  DEFAULT_LIST_NAME = 'queque'
  
  attr_reader :list
  def initialize(list_name = nil)
    @list_name = list_name || next_list_name
    @empty_cond = new_cond
    
    setup_list
    
    super()
  end
  
  def name
    @list_name
  end
  
  def push(*values)
    write_operation { @list.push(*values) }
  end
  
  alias_method :<<, :push
  alias_method :enq, :push
  
  def unshift(*values)
    write_operation { @list.unshift(*values) }
  end
  
  def pop(non_block = false)
    read_operation(non_block) { @list.pop }
  end
  
  alias_method :deq, :pop
  
  def shift(non_block = false)
    read_operation(non_block) { @list.shift }
  end
  
  def empty?
    synchronize { @list.empty? }
  end
  
  def length
    synchronize { @list.size }
  end
  
  alias_method :size, :length
  
  def clear!
    Redis.current.del(@list_name)
    setup_list
  end
  
  private
  
  def next_list_name
    list_regexp = /^#{DEFAULT_LIST_NAME}_\d+/
    
    last_name = Redis.current.keys('*').grep(list_regexp).sort.last
    last_num = last_name ? last_name[list_regexp, 1].to_i : 0
    
    "#{DEFAULT_LIST_NAME}_#{last_num + 1}"
  end
  
  def read_operation(non_block)
    raise ArgumentError, 'no block given' unless block_given?
    
    synchronize do
      raise ThreadError, 'queque empty' if non_block and empty?
      @empty_cond.wait_while { empty? }
      
      yield
    end
  end
  
  def write_operation
    raise ArgumentError, 'no block given' unless block_given?
    
    synchronize do
      yield
      @empty_cond.signal
      self
    end
  end
  
  def setup_list
    @list = Redis::List.new(@list_name, marshal: true)
  end

end
