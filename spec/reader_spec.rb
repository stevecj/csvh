require 'spec_helper'

describe CSVH::Reader do
  describe '::from_file' do
    subject{
      described_class.from_file(example_csv_path)
    }

    let(:example_csv_path) {
      File.join(TEST_DATA_DIR, 'example.csv')
    }

    it "returns a reader for the given CSV file" do
      pending

      expect( subject.headers ).to eq( [:Fruit, :Color] )

      expect( subject.to_a ).to eq( [
        CSV::Row.new( [:Fruit, :Color], %w(Cherry Red)    ),
        CSV::Row.new( [:Fruit, :Color], %w(Orange Orange) )
      ] )
    end
  end
end
