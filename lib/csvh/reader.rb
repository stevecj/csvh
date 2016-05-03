require 'delegate'

module CSVH

  # Sequantially and lazily reads from CSV-formatted data that
  # has a header row. Allows accessing headers before reading
  # any subsequent data rows and/or when no additional data rows
  # are present in the data.
  class Reader
    extend Forwardable

    DEFAULT_CSV_OPTS = {
      headers: :first_row,
      return_headers: true
    }.freeze

    class << self

      # When called without a block argument, returns an open
      # reader for data from the file at the given file_path.
      #
      # When called with a block argument, passes an open reader
      # for data from the file to the given block, closes the
      # reader (and its underlying file IO channel) before
      # returning, and then returns the value that was returned
      # by the block.
      #
      # By default, the underlying CSV object is initialized
      # with default options for data with a header row and to
      # return the header row. Any oadditional options you supply
      # will be added to those defaults or override them.
      #
      # A [Reader] created using this method will delegate all
      # of the same IO methods that a `CSV` created using
      # `CSV#open` does except `close_write`, `flush`, `fsync`,
      # `sync`, `sync=`, and `truncate`. You may call:
      #
      # * binmode()
      # * binmode?()
      # * close()
      # * close_read()
      # * closed?()
      # * eof()
      # * eof?()
      # * external_encoding()
      # * fcntl()
      # * fileno()
      # * flock()
      # * flush()
      # * internal_encoding()
      # * ioctl()
      # * isatty()
      # * path()
      # * pid()
      # * pos()
      # * pos=()
      # * reopen()
      # * seek()
      # * fstat()
      # * tell()
      # * to_i()
      # * to_io()
      # * tty?()
      #
      # @param file_path [String] the path of the file to read.
      # @param opts options for `CSV.new`.
      # @yieldparam [Reader] the new reader.
      # @return [Reader,object]
      #   the new reader or the value returned from the given
      #   block.
      def from_file(file_path, **opts)
        opts = default_csv_opts.merge(opts)
        io = File.open(file_path, 'r')
        csv = CSV.new(io, **opts)
        instance = new(csv)

        if block_given?
          begin
            yield instance
          ensure
            instance.close unless instance.closed?
          end
        else
          instance
        end
      end

      # Returns an open reader for data from given string or
      # readable IO stream.
      #
      # @param data [String, IO] the source of the data to read.
      # @param opts options for `CSV.new`.
      # @return [Reader] the new reader.
      def from_string_or_io(data, **opts)
        opts = default_csv_opts.merge(opts)
        csv = CSV.new(data, **opts)
        new(csv)
      end

      alias  foreach  from_file
      alias  parse    from_string_or_io

      private

      def default_csv_opts
        DEFAULT_CSV_OPTS
      end
    end

    # Returns a new reader based on the given CSV object. The CSV
    # object must be configured to return a header row (a
    # `CSV::ROW` that returns true from its `#header?` method
    # as its first item. The header item must also not have been
    # read yet.
    # @param csv [CSV] A Ruby `::CSV` object.
    def initialize(csv)
      unless csv.return_headers?
        raise \
          InappropreateCsvInstanceError,
           "%{self.class} requires a CSV instance that returns headers." \
          " It needs to have been initialized with non-false/nil values" \
          " for :headers and :return_headers options."
      end
      @csv = csv
    end

    # @return [Reader] the target of the method call.
    def to_csvh_reader
      self
    end

    # Returns the list of column header values from the CSV data.
    #
    # If any rows have already been read, then the result is
    # immediately returned, having been recorded when the header
    # row was initially encountered.
    #
    # If no rows have been read yet, then the first row is read
    # from the data in order to return the result.
    #
    # @return [Array<String>] the column header names.
    def headers
      @headers ||= begin
        row = @csv.readline
        unless row.header_row?
          raise \
            CsvPrematurelyShiftedError,
            "the header row was prematurely read from the underlying CSV object."
        end
        row.headers
      end
    end

    # These methods always delegate to CSV, which may or may not
    # futher delegate them to its underlying file IO object,
    # depending on how it was created.

    def_delegators \
      :@csv,
      :binmode,
      :binmode?,
      :close_read,
      :close,
      :closed?,
      :eof,
      :eof?,
      :external_encoding,
      :fcntl,
      :fileno,
      :flock,
      :flush,
      :internal_encoding,
      :ioctl,
      :isatty,
      :path,
      :pid,
      :pos,
      :pos=,
      :reopen,
      :seek,
      :fstat,
      :tell,
      :to_i,
      :to_io,
      :tty?

    # You can use this method to install a `CSV::Converters`
    # built-in, or provide a block that handles a custom
    # conversion.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :convert

    # Returns the current list of converters in effect.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :converters

    # When given a block, yields each remaining data row of the
    # data source in turn as a `CSV::Row` instance. When called
    # without a block, returns an Enumerator over those rows.
    #
    # Will never yield the header row, however, the headers are
    # available via the #headers method of either the reader or
    # the row object.
    #
    # @yieldparam [CSV::Row]
    def each
      headers
      if block_given?
        @csv.each { |row| yield row }
      else
        @csv.each
      end
    end

    # Returns `true` if all output fields are quoted.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :force_quotes?

    # Identical to #convert, but for header rows.
    #
    # Note that this must be called before reading any rows or
    # calling #headers to have any effect.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :header_convert

    # Returns the current list of converters in effect for
    # headers.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :header_converters

    # Slurps the remaining data rows and returns a `CSV::Table`.
    #
    # This is essentially the same behavior as `CSV#read`, but
    # ensures that the header info has been fetched first, and the
    # resulting table will never include the header row.
    #
    # Note that the Ruby documentation (at least as of 2.2.2) is
    # for `CSV#read` is incomplete and simply says that it
    # returns "an Array of Arrays", but it actually returns a
    # table if a truthy `:headers` option was used when creating
    # the `CSV` object.
    #
    # @return [CSV::Table] a table of remaining unread rows
    def read
      headers
      @csv.read
    end

    alias  readlines read

    # A single data row is pulled from the data source, parsed
    # and returned as a CSV::Row.
    #
    # This is essentially the same behavior as `CSV#shift`, but
    # ensures that the header info has been fetched first, and
    # #shift will never return the header row.
    #
    # @return [CSV::Row] the next previously unread row
    def shift
      headers
      @csv.shift
    end

    alias  gets      shift
    alias  readline  shift

    # Returns `true` if blank lines are skipped by the parser.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :skip_blanks?

    # Returns `true` if `unconverted_fields()` to parsed results.
    #
    # See the documentation for `CSV` in the Ruby standard
    # library for more details.
    def_delegator :@csv, :unconverted_fields?

  end

end
