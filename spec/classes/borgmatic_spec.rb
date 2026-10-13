# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('borgmatic::install') }
        it { is_expected.to contain_package('borgmatic').with_ensure('installed') }

        it 'manages the configuration directory without purging it' do
          is_expected.to contain_file('/etc/borgmatic.d')
            .with_ensure('directory')
            .with_owner('root')
            .with_group('root')
            .with_mode('0755')
            .with_purge(false)
            .with_recurse(false)
            .with_force(false)
            .that_requires('Class[borgmatic::install]')
        end

        it { is_expected.not_to contain_service('borgmatic.timer') }
      end

      context 'with nothing to manage' do
        let(:params) { { manage_package: false, manage_config_dir: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package('borgmatic') }
        it { is_expected.not_to contain_file('/etc/borgmatic.d') }
      end

      context 'with a purged configuration directory elsewhere' do
        let(:params) do
          {
            package_name: 'borgmatic-git',
            package_ensure: 'latest',
            config_dir: '/etc/borgmatic',
            config_dir_group: 'backup',
            config_dir_mode: '0750',
            purge_config_dir: true,
          }
        end

        it { is_expected.to contain_package('borgmatic-git').with_ensure('latest') }

        it do
          is_expected.to contain_file('/etc/borgmatic')
            .with_group('backup')
            .with_mode('0750')
            .with_purge(true)
            .with_recurse(true)
            .with_force(true)
        end
      end

      context 'with the package timer stopped' do
        let(:params) { { package_timer: false } }

        it { is_expected.to contain_service('borgmatic.timer').with_ensure('stopped').with_enable(false).that_requires('Class[borgmatic::install]') }
      end

      context 'with the package timer running' do
        let(:params) { { package_timer: true } }

        it { is_expected.to contain_service('borgmatic.timer').with_ensure('running').with_enable(true) }
      end

      context 'with configurations and timers from hashes' do
        let(:params) do
          {
            configs: { 'system' => { 'repositories' => ['/srv/borg/system'], 'keep_daily' => 7 } },
            timers: { 'system' => { 'on_calendar' => 'hourly' } },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_borgmatic__config('system').with_keep_daily(7) }
        it { is_expected.to contain_file('/etc/borgmatic.d/system.yaml') }
        it { is_expected.to contain_borgmatic__timer('system').with_on_calendar('hourly') }
      end
    end
  end
end
