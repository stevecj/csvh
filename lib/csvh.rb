require 'csv'

require "csvh/version"
require "csvh/reader"

module CSVH
  class InappropreateCsvInstanceError < ArgumentError ; end
  class CsvPrematurelyShiftedError < StandardError ; end
end
