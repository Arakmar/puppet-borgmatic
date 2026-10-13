# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Check' do
  it do
    is_expected.to allow_values(
      'repository',
      'disabled',
      { 'name' => 'archives', 'frequency' => '2 weeks' },
      { 'name' => 'repository', 'frequency' => '4 weeks', 'only_run_on' => ['Saturday'], 'max_duration' => 3600 },
      { 'name' => 'spot', 'count_tolerance_percentage' => 10, 'data_sample_percentage' => 1, 'data_tolerance_percentage' => 0.5, 'xxh64sum_command' => 'xxhsum' },
    )
  end

  it { is_expected.not_to allow_values('everything', { 'frequency' => '2 weeks' }, { 'name' => 'data', 'frequncy' => '2 weeks' }, { 'name' => 'data', 'only_run_on' => [] }, nil) }
end
