# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::authorized_key' do
  def key
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA+Ex/ample= root@client1'
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'client1' }

      context 'with a path restriction' do
        let(:params) { { key: key, user: 'borg-client1', restrict_to_paths: ['/srv/borg/client1'] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('borgmatic::server') }

        it 'forces borg serve on the key, matched on its type and body' do
          is_expected.to contain_file_line('borgmatic::authorized_key client1')
            .with_ensure('present')
            .with_path('/home/borg-client1/.ssh/authorized_keys')
            .with_line("command=\"/usr/bin/borg serve --restrict-to-path /srv/borg/client1\",restrict #{key}")
            .with_match('ssh\-ed25519\ AAAAC3NzaC1lZDI1NTE5AAAA\+Ex/ample=')
            .with_match_for_absence(true)
        end
      end

      context 'with every restriction' do
        let(:pre_condition) { "class { 'borgmatic::server': borg_command => '/usr/local/bin/borg' }" }
        let(:params) do
          {
            key: 'ecdsa-sha2-nistp256 AAAAE2VjZHNh',
            user: 'root',
            restrict_to_paths: ['/srv/borg/a', '/srv/borg/b'],
            restrict_to_repositories: ['/srv/borg/c'],
            append_only: true,
            umask: '0027',
            storage_quota: '1.5T',
            options: ['restrict', 'from="10.0.0.0/8"'],
          }
        end

        it do
          is_expected.to contain_file_line('borgmatic::authorized_key client1')
            .with_path('/root/.ssh/authorized_keys')
            .with_line(
              'command="/usr/local/bin/borg serve --restrict-to-path /srv/borg/a --restrict-to-path /srv/borg/b ' \
              '--restrict-to-repository /srv/borg/c --append-only --umask 0027 --storage-quota 1.5T",' \
              'restrict,from="10.0.0.0/8" ecdsa-sha2-nistp256 AAAAE2VjZHNh',
            )
        end
      end

      context 'with a forced command and a target' do
        let(:params) do
          {
            key: key,
            user: 'borg',
            target: '/etc/ssh/authorized_keys/borg',
            command: 'borg serve --restrict-to-path "/srv/borg/my repo"',
            options: [],
          }
        end

        it do
          is_expected.to contain_file_line('borgmatic::authorized_key client1')
            .with_path('/etc/ssh/authorized_keys/borg')
            .with_line("command=\"borg serve --restrict-to-path \\\"/srv/borg/my repo\\\"\" #{key}")
        end
      end

      context 'with ensure absent' do
        let(:params) { { key: key, user: 'borg', ensure: 'absent' } }

        it { is_expected.to contain_file_line('borgmatic::authorized_key client1').with_ensure('absent') }
      end

      context 'with a malformed key' do
        let(:params) { { key: "#{key}\n", user: 'borg' } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'key'}) }
      end
    end
  end
end
