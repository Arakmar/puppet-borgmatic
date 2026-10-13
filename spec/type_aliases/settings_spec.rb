# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Settings' do
  it { is_expected.to allow_values({}, { 'ping_url' => 'https://hc-ping.com/uuid', 'states' => ['fail'] }, { 'name' => 'all', 'password' => sensitive('secret') }) }
  it { is_expected.not_to allow_values({ '' => 1 }, ['a'], 'a', nil) }
end
