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
      expect( actual ).to respond_to(:to_csvh)
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

        it "returns an enumerator that returns all of the data rows" do
          actual = subject.each
          expect( actual.next ).to eq( CSV::Row.new( %w(A B C), %w(a1 b1 c1) ) )
          expect( actual.next ).to eq( CSV::Row.new( %w(A B C), %w(a2 b2 c2) ) )
          expect{ actual.next }.to raise_exception( StopIteration )
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
          actual = subject.each
          expect( actual.next ).to eq( CSV::Row.new( %w(-A- -B- -C-), %w(A B C) ) )
          expect( actual.next ).to eq( CSV::Row.new( %w(-A- -B- -C-), %w(a1 b1 c1) ) )
          expect( actual.next ).to eq( CSV::Row.new( %w(-A- -B- -C-), %w(a2 b2 c2) ) )
          expect{ actual.next }.to raise_exception( StopIteration )
        end
      end
    end
  end

  describe '::from_file' do
    subject{
      described_class.from_file(example_csv_path)
    }

    let(:example_csv_path) {
      File.join(TEST_DATA_DIR, 'example.csv')
    }

    after do
      subject.close
    end

    it "returns a reader for the given CSV file" do
      expect( subject.headers ).to eq( ['Fruit', 'Color'] )

      expect( subject.each.entries ).to eq( [
        CSV::Row.new( ['Fruit', 'Color'], %w(Cherry Red)    ),
        CSV::Row.new( ['Fruit', 'Color'], %w(Orange Orange) )
      ] )
    end
  end

end
