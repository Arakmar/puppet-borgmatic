# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Compression' do
  it { is_expected.to allow_values('none', 'lz4', 'zstd', 'zstd,3', 'zstd,22', 'zlib,6', 'lzma,9', 'auto,lzma,6', 'auto,zstd', 'obfuscate,110,zstd,3') }
  it { is_expected.not_to allow_values('zstd,', 'lz4,1', 'auto', 'gzip', '', nil) }
end
