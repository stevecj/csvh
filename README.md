# CSVH

A straightforward API to lazily read headers and data rows from
CSV, including in cases where no data rows are present.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'csvh'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install csvh

## Usage

This gem provides a `CSVH::Reader` class that lazily reads from
CSV-formatted data that has a header row. Allows accessing
headers before reading any subsequent data rows and/or when no
additional data rows are present in the data.

The `CSVH::Reader` class is primarily intended to be used in one
of the following ways:

    # Read from a file, and close the file automatically.
    CSVH::Reader.from_file 'the-path-to/my-data.csv' do |reader|
      # reader.headers is an array of header strings.
      puts "Headers: " + reader.headers.inspect

      reader.each do |row|
        # row is a standard Ruby CSV::Row object.
        puts row.to_h.inspect
      end
    end

    # Read from an IO stream.
    reader = CSVH::Reader.from_string_or_io(an_io_stream)

    # reader.headers is an array of header strings.
    puts "Headers: " + reader.headers.inspect

    reader.each do |row|
      # row is a standard Ruby CSV::Row object.
      puts row.to_h.inspect
    end

## Development

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow
you to experiment.

To install this gem onto your local machine, run `bundle exec
rake install`. To release a new version, update the version
number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and
tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/stevecj/csvh.


## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
