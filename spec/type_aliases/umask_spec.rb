# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Umask' do
  it { is_expected.to allow_values('0027', '027', '0077', '0777', '0000') }
  it { is_expected.not_to allow_values('27', '0028', '00277', 27, 0o27, '', nil) }
end
