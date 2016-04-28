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
      @csv = csv
    end

    def headers
      @headers ||= @csv.readline.headers
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
