require 'queque/version'
require 'redis-objects'
require 'monitor'

class Queque
  include MonitorMixin
  
  DEFAULT_LIST_NAME = 'queque'
  
  attr_reader :list
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
    list_regexp = /^#{DEFAULT_LIST_NAME}_(\d+)/
    
    last_num = Redis.current.keys('*').grep(list_regexp)
                 .map {|n| n[list_regexp, 1].to_i }.sort.last
    
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
