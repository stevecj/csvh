require 'spec_helper'

describe CSVH::Reader do

  describe '::new' do
    it "accepts a CSV that treats the first line as headers and returns the headers row" do
      csv = CSV.new(
        "a,b,c\n1,2,3\n",
        headers: :first_row,
        return_headers: true
      )
      actual = described_class.new(csv)
      expect( actual ).to respond_to(:to_csvh)
    end

    it "rejects a CSV that treats the first line as data" do
      csv = CSV.new("a,b,c\n1,2,3\n")
      expect{
        described_class.new(csv)
      }.to raise_exception( CSVH::InappropreateCsvInstanceError )
    end

    it "rejects a CSV that treats the first line as headers, but does not return the header row" do
      csv = CSV.new("a,b,c\n1,2,3\n", headers: :first_row)
      expect{
        described_class.new(csv)
      }.to raise_exception( CSVH::InappropreateCsvInstanceError )
    end
  end

  describe '#headers' do
    subject { described_class.new(csv) }
    let(:csv){ CSV.new(
      "a,b,c\na1,b1,c1\na2,b2,c2\n",
      headers: :first_row,
      return_headers: true
    ) }

    context "with a pristine underlying CSV instance" do
      it "returns an array of the headers from the first row" do
        expect( subject.headers ).to eq( %w(a b c) )
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
