# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::StorageQuota' do
  it { is_expected.to allow_values('500G', '1.5T', '1000000', '10M') }
  it { is_expected.not_to allow_values('500 G', '500GB', 'G', '', 500, nil) }
end
