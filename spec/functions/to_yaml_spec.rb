# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::to_yaml' do
  it { is_expected.not_to be_nil }

  it 'renders the options with a header, leaving undef ones out' do
    is_expected.to run
      .with_params({ 'source_directories' => ['/etc'], 'keep_daily' => 7, 'keep_weekly' => nil, 'checks' => [{ 'name' => 'repository' }] })
      .and_return("# Managed by Puppet\n---\nsource_directories:\n- \"/etc\"\nkeep_daily: 7\nchecks:\n- name: repository\n")
  end

  it 'never folds long values' do
    command = "echo #{'x' * 200}"
    expect(call_function('borgmatic::to_yaml', { 'before_backup' => [command] })).to include("- #{command}\n")
  end

  it 'returns a Sensitive document when an option is Sensitive' do
    result = call_function('borgmatic::to_yaml', { 'mariadb_databases' => [{ 'name' => 'all', 'password' => sensitive('secret') }] })
    expect(result).to be_a(Puppet::Pops::Types::PSensitiveType::Sensitive)
    expect(result.unwrap).to eq("# Managed by Puppet\n---\nmariadb_databases:\n- name: all\n  password: secret\n")
  end

  it { is_expected.to run.with_params('nope').and_raise_error(ArgumentError) }
end
