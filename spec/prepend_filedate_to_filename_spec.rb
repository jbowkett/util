require 'rspec'
require_relative '../lib/prepend_filedate_to_filename'

describe PrependFiledateToFilename do

  let(:date) { Date.parse('18-Dec-2004')}
  it 'should format a date in yyyymmDD format' do

    PrependFiledateToFilename.new().format(date).should == '20041218'
  end
end
