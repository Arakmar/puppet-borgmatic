# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Action' do
  it { is_expected.to allow_values('create', 'prune', 'compact', 'check', 'repo-create', 'export-tar', 'break-lock') }
  it { is_expected.not_to allow_values('backup', 'rcreate', 'init', '', nil) }
end
