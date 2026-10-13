# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::contains_sensitive' do
  it { is_expected.not_to be_nil }
  it { is_expected.to run.with_params(sensitive('x')).and_return(true) }
  it { is_expected.to run.with_params({ 'a' => [{ 'b' => sensitive('x') }] }).and_return(true) }
  it { is_expected.to run.with_params(['a', sensitive('x')]).and_return(true) }
  it { is_expected.to run.with_params({ 'a' => [{ 'b' => 'x' }], 'c' => nil }).and_return(false) }
  it { is_expected.to run.with_params('x').and_return(false) }
end
