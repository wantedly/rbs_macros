# rbs-macros

Rubyists💎 love metaprogramming.

**rbs-macros** bridges between [RBS](https://github.com/ruby/rbs) and metaprogramming,
by allowing you to define a macro,
which is then used to generate RBS definitions
based on macro invocations.

## Installation

```sh
bundle add rbs-macros --group development,test --require false
```

Or equivalently, add to Gemfile:

```ruby
group :development, :test do
  gem "rbs-macros", "~> [VERSION]", require: false
end
```

Then run `bundle install`.

## Usage

> [!NOTE]
> at the time of writing, rbs-macros is still in early development,
> and the API is subject to change.

Assumes you have already set up `rbs_collection.yaml` via `rbs collection init`.

Add to Rakefile:

```ruby
desc "Generate RBS files using macros"
task :rbs_gen do
  require "rbs_macros"
  require "rbs_macros/macros/forwardable"
  RbsMacros.run do |config|
    lock_path = Pathname("rbs_collection.lock.yaml")
    config.loader.add_collection(
      RBS::Collection::Config::Lockfile.from_lockfile(
        lockfile_path: lock_path,
        data: YAML.load_file(lock_path.to_s)
      )
    )
    config.macros << RbsMacros::Macros::ForwardableMacros.new
    config.macros << RbsMacros::Macros::SingleForwardableMacros.new
  end
end
```

Then run:

```
bundle exec rake rbs_gen
```

## Example

Suppose there are the following files:

```ruby
# lib/array_wrapper.rb
class ArrayWrapper
  extend Forwardable
  def_delegators :@storage, :[], :size
end
```

```rbs
# sig/array_wrapper.rbs
class ArrayWrapper[T]
  extend Forwardable
  @storage: Array[T]
end
```

Then the output will be:

```rbs
# sig/generated/array_wrapper.rbs
class ArrayWrapper
  def []: (::int index) -> T
        | (::int start, ::int length) -> ::Array[T]?
        | (::Range[::Integer?] range) -> ::Array[T]?

  def size: () -> ::Integer
end
```

## Future plans

- You will be able to define sharable macros and included them in your gem.
  For example, the `ffi` gem may include its own macros to generate RBS files for FFI definitions.
- Additionally, you will be able to load all the relevant macros based on the gem list in Gemfile.
- The behavior is currently largely dependent on the order the source files are processed.
  I will try to stabilize it to some extent in the future.
- Possible new builtin macros:
  - Improved `forwardable` macros
  - `Struct`/`Data` macros
  - FFI
  - ActiveRecord

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wantedly/rbs_macros. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/wantedly/rbs_macros/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RbsMacros project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wantedly/rbs_macros/blob/main/CODE_OF_CONDUCT.md).
