# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      def package
        (facts[:os]['family'] == 'Archlinux') ? 'borg' : 'borgbackup'
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package(package).with_ensure('installed') }

        it do
          is_expected.to contain_file('/srv/borg')
            .with_ensure('directory')
            .with_owner('root')
            .with_group('root')
            .with_mode('0755')
        end
      end

      context 'with nothing to manage' do
        let(:params) { { manage_package: false, manage_base_path: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package(package) }
        it { is_expected.not_to contain_file('/srv/borg') }
      end

      context 'with custom parameters' do
        let(:params) do
          {
            package_name: 'borgbackup2',
            package_ensure: 'latest',
            base_path: '/mnt/backup',
            group: 'borgmatic',
            mode: '0750',
          }
        end

        it { is_expected.to contain_package('borgbackup2').with_ensure('latest') }
        it { is_expected.to contain_file('/mnt/backup').with_group('borgmatic').with_mode('0750') }
      end

      context 'with repositories and authorized keys from hashes' do
        let(:params) do
          {
            encryption: 'none',
            repositories: { 'client1' => { 'owner' => 'borg-client1' } },
            authorized_keys: {
              'monitoring' => {
                'user' => 'borg-check',
                'key' => 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample nrpe@client1',
                'restrict_to_paths' => ['/srv/borg/client1'],
              },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_borgmatic__repository('client1').with_owner('borg-client1') }
        it { is_expected.to contain_exec('borg init /srv/borg/client1').with_command(%r{--encryption none}) }
        it { is_expected.to contain_borgmatic__authorized_key('monitoring').with_user('borg-check') }
        it { is_expected.to contain_file_line('borgmatic::authorized_key monitoring').with_path('/home/borg-check/.ssh/authorized_keys') }
      end
    end
  end
end
