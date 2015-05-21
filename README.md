# Queque

Queque is a simple Redis-backed queue, similar in its functionality to Ruby's Queue class. Each Queque instance is backed by list in Redis. This functionality comes directly from the [redis-objects](https://github.com/nateware/redis-objects) library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'queque'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install queque

## Usage

To create a new Queque, just call `Queque.new`. You can specify a name for the behind-the-scenes Redis list, otherwise one will be chosen automatically. If you specify a name that already exists (as a Redis list) then the Queque instance will be populated with the list's existing data. _Note that the Redis key will not be added until at least one object is added to the list._

Using Queque is very similar to using Ruby's Queue class. Queque leverages **redis-object**'s transparent Marshal-ing ability so that complex data types can used without any hassle. 

    # Creates a new list in Redis called "queque_1"
    q1 = Queque.new
    
    # Creates a new list in Redis called "queque_2"
    q2 = Queque.new
    
    # Creates a new list in Redis called "one_tough_queque"
    q3 = Queque.new "one_tough_queque"
    
    q3 << [1,2,3] << {awesome: true} << "A fair day"
    
    q3.pop
    # => "A fair day"
    
    q3.shift
    # => [1, 2, 3]
    
    # Clears all data
    q3.clear!
    
The [Redis library](https://github.com/redis/redis-rb) will automatically select `redis://127.0.0.1:6379/0` as the Redis server. If you need to connect to a different Redis server or database, you can set `Redis.current` before making your Queques.

    Redis.current = Redis.new url: 'redis://some-other-server.net:12345/67' 
    


## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/hololeap/queque/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
