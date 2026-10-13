# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Verbosity' do
  it { is_expected.to allow_values(-2, -1, 0, 1, 2) }
  it { is_expected.not_to allow_values(-3, 3, '1', nil) }
end
