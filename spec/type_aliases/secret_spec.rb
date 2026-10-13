# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Secret' do
  it { is_expected.to allow_values('secret', '', sensitive('secret')) }
  it { is_expected.not_to allow_values(1, nil, sensitive(1)) }
end
