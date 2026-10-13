# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::normalize' do
  it { is_expected.not_to be_nil }

  it 'drops undef values and unwraps Sensitive values at any depth' do
    is_expected.to run
      .with_params({ 'a' => nil, 'b' => [1, nil, sensitive('x')], 'c' => { 'd' => nil, 'e' => sensitive({ 'f' => sensitive('y') }) }, 'g' => {}, 'h' => [] })
      .and_return({ 'b' => [1, 'x'], 'c' => { 'e' => { 'f' => 'y' } }, 'g' => {}, 'h' => [] })
  end

  it 'preserves insertion order' do
    expect(call_function('borgmatic::normalize', { 'z' => 1, 'a' => 2, 'm' => nil, 'b' => 3 }).keys).to eq(%w[z a b])
  end

  it { is_expected.to run.with_params(sensitive('x')).and_return('x') }
  it { is_expected.to run.with_params('x').and_return('x') }
  it { is_expected.to run.with_params(false).and_return(false) }
end
