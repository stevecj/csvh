require 'delegate'

module CSVH

  class Reader
    extend Forwardable

    DEFAULT_CSV_OPTS = {
      headers: :first_row,
      return_headers: true
    }.freeze

    class << self

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

    def to_csvh
      self
    end

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

    def_delegators \
      :@csv,
      :close,
      :closed?

    def each
      headers
      if block_given?
        @csv.each { |row| yield row }
      else
        @csv.each
      end
    end

  end

end
