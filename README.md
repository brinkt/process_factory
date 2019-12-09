# ProcessFactory

Allows a synchronized calculation, presumably one which is very expensive, blocking, or network-reliant, to be performed across (n) threads or (x) processes, which may result in a dramatic performance improvement.

The calculation can first be spread across (x) processes, taking advantage of multi-core CPUs, then be spread across (n) threads, taking advantage of available CPU during blocking/waiting events, in a more complex nested setup.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'process_factory'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install process_factory

## Usage

Require `process_factory` gem, then include `ProcessFactory` within your class.

```ruby
require 'process_factory'

class MyClass
  include ProcessFactory
  ...
end
```

Define three(3) methods: `pre_process`, `worker_process`, and `post_process`.

`ProcessFactory` uses these methods to distribute the workload.


```ruby
require 'process_factory'

class MyClass
  include ProcessFactory
  
  def pre_process(options)
    # merge instructions from {object/file/database} into options
    # runs within Mutex.synchronize
    
    options # pass options to worker_process
  end
  
  def worker_process(options)
    # read options, perform expensive/blocking calculation, merge results
    # runs within separate thread/process
    
    options # pass options to post_process
  end
  
  def post_process(options)
    # save worker results(found within options) to {object/file/database}
    # runs within Mutex.synchronize
  end
  
end
```

Since `pre_process` and `post_process` are run within `Mutex.synchronize` across all threads, logic should be kept to a bare minimum.

Maximize `worker_process` by doing more or processing more chunks of data at one time.

Finally, to tie it all together, create an instance of the class and run `processfactory` on it passing in an `options` hash as the only argument:

```ruby
mc = MyClass.new

mc.processfactory({
  mode:   'p',
  count:   4,
  pre:    'pre_process',
  worker: 'worker_process',
  post:   'post_process'
})
```

**Mode** is defined as `p = Processes`, `t = Threads`, `d = Debug`.

**Count** is the number of threads or processes to use.

**Pre**, **worker**, and **post** allow customization of the three(3) *required* methods.

## Example

For testing purposes and as an example, refer to `TestCrackSHA256` found within [lib/test_crack_sha256.rb](lib/test_crack_sha256.rb).

This code chooses a random number between 1 and 100 million, hashes it with `sha256` and *saves* that result, but *forgets* the original number.

Then, order to determine the original random number, the code has to guess and check each possible combination between 0 and 99,999,999.

Since this computer has a quad-core processor, the code was run in `p = Processes` mode with `count = 4`:

    $ bin/console
    [1] pry(main)> t = TestCrackSHA256.new('p', 4)

Shown are the `@options` used to configure, the 4 separate forked processes waiting for instructions in `@workers`, and the sha256 hash of the random number as `@target`:

    => #<TestCrackSHA256:0x00000001999d90
    @factory=#<ProcessFactory::Factory:0x00000001991c08
    @mutex=#<Thread::Mutex:0x000000019903d0>,
    @options={:mode=>"p", :count=>4, :pre=>"brute_pre", :worker=>"brute_worker", :post=>"brute_post"},
    @parent=#<TestCrackSHA256:0x00000001999d90 ...>,
    @workers=
    [#<ProcessFactory::Worker:0x0 @pid=7397, @read=#<IO:fd 10>, @write=#<IO:fd 9>>,
     #<ProcessFactory::Worker:0x1 @pid=7400, @read=#<IO:fd 12>, @write=#<IO:fd 11>>,
     #<ProcessFactory::Worker:0x2 @pid=7403, @read=#<IO:fd 14>, @write=#<IO:fd 13>>,
     #<ProcessFactory::Worker:0x3 @pid=7406, @read=#<IO:fd 16>, @write=#<IO:fd 15>>]>,
    @target="116a8141be38925266445c65453974a99e62261bcc50ce5cbe72342877a161af">

To run the factory use:

    [2] pry(main)> t.factory.run
    
The results are displayed in console:

    Processed: 9000000 combos!
    Processed: 21000000 combos!
    Processed: 33000000 combos!
    Processed: 45000000 combos!
    Processed: 57000000 combos!
    Processed: 69000000 combos!
    Found valid combo: 77838225

This process was fast because it used **all 4 cores of the CPU** instead of just one.

Obviously if this was not for testing, each sha256 hash of every possible combo would be saved to a database the first time, then simply queried against for future attempts, but the objective here is to simulate hard work.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Admin Deployment

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

