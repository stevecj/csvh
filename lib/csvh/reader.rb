require 'delegate'

module CSVH
  class Reader
    extend Forwardable

    def self.from_file(file_path)
      io = File.open(file_path, 'r')
      csv = CSV.new(
        io,
        headers: :first_row,
        return_headers: true
      )
      new(csv)
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
      :close

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
