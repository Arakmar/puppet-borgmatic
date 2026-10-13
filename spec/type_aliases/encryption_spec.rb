# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Encryption' do
  it { is_expected.to allow_values('none', 'authenticated', 'authenticated-blake2', 'repokey', 'repokey-blake2') }
  it { is_expected.not_to allow_values('keyfile', 'keyfile-blake2', 'repokey-aes-ocb', '', nil) }
end
