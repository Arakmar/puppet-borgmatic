# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::repository' do
  key = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample root@client1'

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'client1' }

      package = (os_facts[:os]['family'] == 'Archlinux') ? 'borg' : 'borgbackup'

      context 'with a passphrase' do
        let(:params) { { owner: 'borg-client1', passphrase: 'secret' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('borgmatic::server') }

        it do
          is_expected.to contain_file('/srv/borg/client1')
            .with_ensure('directory')
            .with_owner('borg-client1')
            .with_group('borg-client1')
            .with_mode('0700')
            .that_requires('File[/srv/borg]')
        end

        it 'initialises the repository once as root and hands it over to its owner' do
          is_expected.to contain_exec('borg init /srv/borg/client1')
            .with_command('/usr/bin/borg init --encryption repokey-blake2 /srv/borg/client1 && chown -R borg-client1:borg-client1 /srv/borg/client1')
            .with_creates('/srv/borg/client1/config')
            .with_environment(['BORG_PASSPHRASE=secret'])
            .with_provider('shell')
            .without_user
            .that_requires(['File[/srv/borg/client1]', "Package[#{package}]"])
        end

        it { is_expected.not_to contain_borgmatic__authorized_key('client1_root') }
      end

      context 'with every option' do
        let(:pre_condition) { "class { 'borgmatic::server': base_path => '/mnt/backup', manage_package => false }" }
        let(:params) do
          {
            path: '/mnt/backup/borgmatic_client1',
            owner: 'borg-client1',
            group: 'borgmatic',
            mode: '0750',
            encryption: 'authenticated-blake2',
            passphrase: sensitive('s3cret'),
            umask: '0027',
            append_only: true,
            storage_quota: '500G',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/mnt/backup/borgmatic_client1').with_group('borgmatic').with_mode('0750') }

        it do
          is_expected.to contain_exec('borg init /mnt/backup/borgmatic_client1')
            .with_command(
              '/usr/bin/borg init --encryption authenticated-blake2 --umask 0027 --append-only --storage-quota 500G /mnt/backup/borgmatic_client1 ' \
              '&& chown -R borg-client1:borgmatic /mnt/backup/borgmatic_client1',
            )
            .with_environment(['BORG_PASSPHRASE=s3cret'])
        end
      end

      context 'without encryption' do
        let(:params) { { encryption: 'none' } }

        it { is_expected.to contain_exec('borg init /srv/borg/client1').with_command(%r{\A/usr/bin/borg init --encryption none }).with_environment([]) }
      end

      context 'with the encryption of the server' do
        let(:pre_condition) { "class { 'borgmatic::server': encryption => 'none' }" }

        it { is_expected.to contain_exec('borg init /srv/borg/client1').with_command(%r{--encryption none}) }
      end

      context 'without a passphrase' do
        it { is_expected.to compile.and_raise_error(%r{a passphrase is required with the repokey-blake2 encryption}) }
      end

      context 'with a keyfile encryption' do
        let(:params) { { encryption: 'keyfile', passphrase: 'secret' } }

        it { is_expected.to compile.and_raise_error(%r{encryption}) }
      end

      context 'with authorized keys' do
        let(:params) do
          {
            owner: 'borg-client1',
            passphrase: 'secret',
            umask: '0027',
            authorized_keys: {
              'root' => { 'key' => key },
              'check' => { 'key' => key.sub('Example', 'Other'), 'user' => 'borg-check', 'append_only' => true, 'umask' => '0077' },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_borgmatic__authorized_key('client1_root')
            .with_user('borg-client1')
            .with_key(key)
            .with_restrict_to_paths(['/srv/borg/client1'])
            .with_umask('0027')
        end

        it { is_expected.to contain_file_line('borgmatic::authorized_key client1_root').with_path('/home/borg-client1/.ssh/authorized_keys') }

        it do
          is_expected.to contain_borgmatic__authorized_key('client1_check')
            .with_user('borg-check')
            .with_append_only(true)
            .with_umask('0077')
            .with_restrict_to_paths(['/srv/borg/client1'])
        end

        it do
          is_expected.to contain_file_line('borgmatic::authorized_key client1_check')
            .with_path('/home/borg-check/.ssh/authorized_keys')
            .with_line(%r{\Acommand="/usr/bin/borg serve --restrict-to-path /srv/borg/client1 --append-only --umask 0077",restrict ssh-ed25519 })
        end
      end
    end
  end
end
