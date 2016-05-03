require 'spec_helper'

describe CSVH::Reader do
  let(:csv_source_data) {
    <<-EOS
A,B,C
a1,b1,c1
a2,b2,c2
    EOS
  }

  describe '::new' do
    it "accepts a CSV that treats the first line as headers and returns the headers row" do
      csv = CSV.new(
        csv_source_data,
        headers: :first_row,
        return_headers: true
      )
      actual = described_class.new(csv)
      expect( actual ).to respond_to(:to_csvh_reader)
    end

    it "rejects a CSV that treats the first line as data" do
      csv = CSV.new(csv_source_data)
      expect{
        described_class.new(csv)
      }.to raise_exception( CSVH::InappropreateCsvInstanceError )
    end

    it "rejects a CSV that treats the first line as headers, but does not return the header row" do
      csv = CSV.new(csv_source_data, headers: :first_row)
      expect{
        described_class.new(csv)
      }.to raise_exception( CSVH::InappropreateCsvInstanceError )
    end
  end

  describe "an instance" do
    subject { described_class.new(csv) }

    let(:csv){
      CSV.new(csv_source_data, csv_options)
    }

    let(:csv_options) { {
      headers: :first_row,
      return_headers: true
    } }

    describe '#headers' do
      context "with a pristine, typical underlying CSV instance" do
        it "returns an array of the headers from the first row" do
          expect( subject.headers ).to eq( %w(A B C) )
        end
      end

      context "with an underlying CSV instance that has hard-coded headers" do
        let(:csv_options) { {
          headers: %w(-A- -B- -C-),
          return_headers: true
        } }

        it "returns an array of the hard-coded headers" do
          expect( subject.headers ).to eq( %w(-A- -B- -C-) )
        end
      end

      context "with an underlying CSV instance that was prematurely shifted" do
        before do
          csv.shift
        end

        it "fails with an appropriate exception" do
          expect{
            subject.headers
          }.to raise_exception( CSVH::CsvPrematurelyShiftedError )
        end
      end
    end

    describe "#shift" do
      context "before accessing #headers or reading any data rows" do
        it "reads the first data row" do
          expect( subject.shift ).to eq(
            CSV::Row.new( %w(A B C), %w(a1 b1 c1) ),
          )
        end
      end

      context "after accessing #headers, before reading any data rows" do
        before do
          subject.headers
        end

        it "reads the first data row" do
          expect( subject.shift ).to eq(
            CSV::Row.new( %w(A B C), %w(a1 b1 c1) ),
          )
        end
      end

      context "after previously reading the first data row using #shift" do
        before do
          subject.shift
        end

        it "reads the second data row" do
          expect( subject.shift ).to eq(
            CSV::Row.new( %w(A B C), %w(a2 b2 c2) )
          )
        end
      end
    end

    describe "#each" do
      context "with a typical underlying CSV instance" do
        it "calls the given block for each data row when given a block argument" do
          got_data_rows = []
          subject.each do |row|
            got_data_rows << row
          end
          expect( got_data_rows ).to eq( [
            CSV::Row.new( %w(A B C), %w(a1 b1 c1) ),
            CSV::Row.new( %w(A B C), %w(a2 b2 c2) )
          ] )
        end

        it "returns an enumerator that returns all of the data rows when given no block argument" do
          actual = subject.each
          expect( actual.next ).to eq( CSV::Row.new( %w(A B C), %w(a1 b1 c1) ) )
          expect( actual.next ).to eq( CSV::Row.new( %w(A B C), %w(a2 b2 c2) ) )
          expect{ actual.next }.to raise_exception( StopIteration )
        end

        it "enumerates previously unread rows when a row has been previously read" do
          subject.shift
          expect( subject.each.entries ).to eq( [
            CSV::Row.new( %w(A B C), %w(a2 b2 c2) )
          ] )
        end
      end

      context "with an underlying CSV instance that has hard-coded headers" do
        let(:csv_options) { {
          headers: %w(-A- -B- -C-),
          return_headers: true
        } }

        it "calls the given block for each row (including the 1st) when given a block argument" do
          got_data_rows = []
          subject.each do |row|
            got_data_rows << row
          end
          expect( got_data_rows ).to eq( [
            CSV::Row.new( %w(-A- -B- -C-), %w(A B C) ),
            CSV::Row.new( %w(-A- -B- -C-), %w(a1 b1 c1) ),
            CSV::Row.new( %w(-A- -B- -C-), %w(a2 b2 c2) )
          ] )
        end

        it "returns an enumerator that returns all of the rows (including the 1st)" do
          # The first row is a data row when headers are hard-coded.
          actual = subject.each
          expect( actual.next ).to eq( CSV::Row.new( %w(-A- -B- -C-), %w(A B C) ) )
          expect( actual.next ).to eq( CSV::Row.new( %w(-A- -B- -C-), %w(a1 b1 c1) ) )
          expect( actual.next ).to eq( CSV::Row.new( %w(-A- -B- -C-), %w(a2 b2 c2) ) )
          expect{ actual.next }.to raise_exception( StopIteration )
        end
      end
    end

    describe '#read' do
      it "returns a table containing the parsed csv data when no rows previously read" do
        actual_table = subject.read

        expect( actual_table ).to respond_to(:to_csv)
        expect( actual_table.each.entries ).to eq( [
          CSV::Row.new( %w(A B C), %w(a1 b1 c1) ),
          CSV::Row.new( %w(A B C), %w(a2 b2 c2) )
        ] )
      end

      it "returns a table of remaining rows data when a row was previously read" do
        subject.shift
        actual_table = subject.read

        expect( actual_table ).to respond_to(:to_csv)
        expect( actual_table.each.entries ).to eq( [
          CSV::Row.new( %w(A B C), %w(a2 b2 c2) )
        ] )
      end
    end

  end

  describe '::from_file' do
    let(:example_csv_path) {
      File.join(TEST_DATA_DIR, 'example.csv')
    }

    it "returns a reader for the given CSV file when not given a block argument" do
      begin
        reader = described_class.from_file(example_csv_path)
        expect_reader_for_file_data reader
      ensure
        reader.close if reader && (! reader.closed?)
      end
    end

    it "passes an open reader for the file to the given block" do
      block_called = false
      reader = nil

      begin
        described_class.from_file(example_csv_path) do |r|
          block_called = true
          reader = r
          expect_reader_for_file_data r
        end

      ensure
        reader.close if reader && (! reader.closed?)
      end

      expect( block_called ).to eq( true )
    end

    def expect_reader_for_file_data(reader)
      expect( reader.headers ).to eq( ['Fruit', 'Color'] )

      expect( reader.each.entries ).to eq( [
        CSV::Row.new( ['Fruit', 'Color'], %w(Cherry Red)    ),
        CSV::Row.new( ['Fruit', 'Color'], %w(Orange Orange) )
      ] )
    end

    it "closes the reader that was passed to the given normally-executing block before returning" do
      begin
        reader = nil

        described_class.from_file(example_csv_path) do |r|
          reader = r
        end

        expect( reader ).to be_closed

      ensure
        reader.close if reader && (! reader.closed?)
      end
    end

    it "closes the reader that was passed to the given exception-raising block before returning" do
      begin
        reader = nil

        begin
          described_class.from_file(example_csv_path) do |r|
            reader = r
            raise StandardError
          end
        rescue
        end

        expect( reader ).to be_closed

      ensure
        reader.close if reader && (! reader.closed?)
      end
    end

    it "propagates an exception raised in the given block" do
      begin
        reader = nil

        expect{
          described_class.from_file(example_csv_path) do |r|
            reader = r
            raise StandardError, 'Wibble'
          end
        }.to raise_exception( StandardError, 'Wibble' )

      ensure
        reader.close if reader && (! reader.closed?)
      end
    end

    it "returns the value that is returned by the given block" do
      reader = nil

      begin

        actual = described_class.from_file(example_csv_path) do |r|
          reader = r
          :expected
        end

      ensure
        reader.close if reader && (! reader.closed?)
      end

      expect( actual ).to eq( :expected )
    end

  end

  describe '::from_string_or_io' do
    subject{
      described_class.from_string_or_io(example_data)
    }

    let(:example_data_string) {
      <<-EOS
Make,Model
Ford,Prefect
Chevrolet,Superurban
      EOS
    }

    after do
      subject.close
    end

    context "given CSV data in a string" do
      let(:example_data) { example_data_string }

      it "returns a reader for the given CSV string data" do
        it_returns_reader_for_given_csv_data
      end
    end

    context "given CSV data through an input stream" do
      let(:example_data) {
        StringIO.new(example_data_string)
      }

      it "returns a reader for the given CSV stream data" do
        it_returns_reader_for_given_csv_data
      end
    end

    def it_returns_reader_for_given_csv_data
        expect( subject.headers ).to eq( ['Make', 'Model'] )

        expect( subject.each.entries ).to eq( [
          CSV::Row.new( ['Make', 'Model'], %w(Ford Prefect)    ),
          CSV::Row.new( ['Make', 'Model'], %w(Chevrolet Superurban) )
        ] )
    end
  end

end
