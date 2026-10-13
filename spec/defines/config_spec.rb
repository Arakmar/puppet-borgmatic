# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::config' do
  let(:title) { 'system' }

  path = '/etc/borgmatic.d/system.yaml'

  # Every parameter, in the order of the define, with its rendering
  full_options = [
    [:constants, { 'host' => 'client1' }],
    [:source_directories, ['/etc', '/home']],
    [:source_directories_must_exist, true],
    [:repositories,
     ['ssh://borg@backup1.example.org/srv/borg/{host}', { 'path' => 'ssh://borg@backup2.example.org/srv/borg/{host}', 'label' => 'backup2', 'append_only' => true }],
     [{ 'path' => 'ssh://borg@backup1.example.org/srv/borg/{host}' }, { 'path' => 'ssh://borg@backup2.example.org/srv/borg/{host}', 'label' => 'backup2', 'append_only' => true }]],
    [:working_directory, '/'],
    [:one_file_system, true],
    [:numeric_ids, true],
    [:atime, false],
    [:ctime, true],
    [:birthtime, false],
    [:read_special, false],
    [:flags, true],
    [:files_changed, 'mtime'],
    [:files_cache, 'ctime,size,inode'],
    [:local_path, 'borg'],
    [:remote_path, '/usr/local/bin/borg'],
    [:patterns, ['R /', '- /home/*/.cache']],
    [:patterns_from, ['/etc/borgmatic/patterns']],
    [:exclude_patterns, ['*.pyc', '/var/cache']],
    [:exclude_from, ['/etc/borgmatic/excludes']],
    [:exclude_caches, true],
    [:exclude_if_present, ['.nobackup']],
    [:keep_exclude_tags, true],
    [:exclude_nodump, true],
    [:user_runtime_directory, '/run/borgmatic'],
    [:user_state_directory, '/var/lib/borgmatic'],
    [:encryption_passcommand, 'cat /etc/borgmatic/passphrase'],
    [:checkpoint_interval, 1800],
    [:checkpoint_volume, 1_048_576],
    [:chunker_params, '19,23,21,4095'],
    [:compression, 'zstd,3'],
    [:recompress, 'if-different'],
    [:upload_rate_limit, 1000],
    [:upload_buffer_size, 100],
    [:retries, 1],
    [:retry_wait, 10],
    [:temporary_directory, '/var/tmp'],
    [:ssh_command, 'ssh -i /root/.ssh/id_backup'],
    [:borg_base_directory, '/root'],
    [:borg_config_directory, '/root/.config/borg'],
    [:borg_cache_directory, '/var/cache/borg'],
    [:use_chunks_archive, false],
    [:borg_files_cache_ttl, 20],
    [:borg_security_directory, '/root/.config/borg/security'],
    [:borg_keys_directory, '/root/.config/borg/keys'],
    [:borg_key_file, '/root/.config/borg/keys/key'],
    [:borg_exit_codes, [{ 'code' => 107, 'treat_as' => 'warning' }]],
    [:umask, '0027', 27],
    [:lock_wait, 120],
    [:archive_name_format, '{hostname}-{now}'],
    [:match_archives, 'sh:{hostname}-*'],
    [:relocated_repo_access_is_ok, true],
    [:unknown_unencrypted_repo_access_is_ok, false],
    [:check_i_know_what_i_am_doing, true],
    [:extra_borg_options, { 'create' => '--noacls --noxattrs', 'prune' => '--save-space' }],
    [:keep_within, '3H'],
    [:keep_secondly, 60],
    [:keep_minutely, 60],
    [:keep_hourly, 24],
    [:keep_daily, 7],
    [:keep_weekly, 4],
    [:keep_monthly, 6],
    [:keep_yearly, 1],
    [:keep_13weekly, 4],
    [:keep_3monthly, 4],
    [:compact_threshold, 10],
    [:checks,
     ['archives',
      { 'name' => 'repository', 'frequency' => '2 weeks', 'only_run_on' => ['Saturday'], 'max_duration' => 3600 },
      { 'name' => 'spot', 'count_tolerance_percentage' => 10, 'data_sample_percentage' => 1, 'data_tolerance_percentage' => 0.5 }],
     [{ 'name' => 'archives' },
      { 'name' => 'repository', 'frequency' => '2 weeks', 'only_run_on' => ['Saturday'], 'max_duration' => 3600 },
      { 'name' => 'spot', 'count_tolerance_percentage' => 10, 'data_sample_percentage' => 1, 'data_tolerance_percentage' => 0.5 }]],
    [:check_repositories, ['backup2']],
    [:check_last, 3],
    [:verbosity, -1],
    [:syslog_verbosity, 1],
    [:log_file, '/var/log/borgmatic.log'],
    [:log_file_verbosity, 1],
    [:log_file_format, '{message}'],
    [:monitoring_verbosity, 1],
    [:statistics, 'quick'],
    [:default_actions, true],
    [:skip_actions, ['compact']],
    [:commands, [{ 'before' => 'action', 'when' => ['create'], 'run' => ['echo before'] }, { 'after' => 'error', 'states' => ['fail'], 'run' => ['echo "{error}"'] }]],
    [:before_actions, ['echo before_actions']],
    [:before_backup, ['echo before_backup']],
    [:before_prune, ['echo before_prune']],
    [:before_compact, ['echo before_compact']],
    [:before_check, ['echo before_check']],
    [:before_extract, ['echo before_extract']],
    [:after_backup, ['echo after_backup']],
    [:after_compact, ['echo after_compact']],
    [:after_prune, ['echo after_prune']],
    [:after_check, ['echo after_check']],
    [:after_extract, ['echo after_extract']],
    [:after_actions, ['echo after_actions']],
    [:on_error, ['echo "{configuration_filename}" "{repository}" "{output}"']],
    [:before_everything, ['echo before_everything']],
    [:after_everything, ['echo after_everything']],
    [:postgresql_databases, [{ 'name' => 'all', 'username' => 'postgres' }]],
    [:mariadb_databases, [{ 'name' => 'all', 'password' => RSpec::Puppet::Sensitive.new('mariadb') }], [{ 'name' => 'all', 'password' => 'mariadb' }]],
    [:mysql_databases, [{ 'name' => 'app', 'hostname' => 'db.example.org', 'port' => 3306 }]],
    [:sqlite_databases, [{ 'name' => 'app', 'path' => '/var/lib/app/app.db' }]],
    [:mongodb_databases, [{ 'name' => 'all' }]],
    [:ntfy, { 'topic' => 'backups' }],
    [:pushover, { 'token' => 'token', 'user' => 'user' }],
    [:zabbix, { 'server' => 'https://zabbix.example.org/zabbix/api_jsonrpc.php', 'itemid' => 55_105 }],
    [:apprise, { 'services' => [{ 'url' => 'gotify://hostname/token', 'label' => 'gotify' }] }],
    [:healthchecks, 'https://hc-ping.com/uuid', { 'ping_url' => 'https://hc-ping.com/uuid' }],
    [:uptime_kuma, { 'push_url' => 'https://kuma.example.org/api/push/abcd' }],
    [:cronitor, 'https://cronitor.link/d3x0c1', { 'ping_url' => 'https://cronitor.link/d3x0c1' }],
    [:pagerduty, RSpec::Puppet::Sensitive.new('a177cad45bd374409f78906a810a3074'), { 'integration_key' => 'a177cad45bd374409f78906a810a3074' }],
    [:loki, { 'url' => 'http://localhost:3100/loki/api/v1/push', 'labels' => { 'app' => 'borgmatic' } }],
    [:sentry, { 'data_source_name_url' => 'https://key@example.ingest.sentry.io/1', 'monitor_slug' => 'backups' }],
    [:zfs, {}],
    [:btrfs, {}],
    [:lvm, { 'snapshot_size' => '10%ORIGIN' }],
  ]
  full_params = full_options.to_h { |option| [option[0], option[1]] }.merge(options: { 'archive_hostname' => '{host}' })
  full_config = full_options.to_h { |option| [option[0].to_s, option.fetch(2, option[1])] }.merge('archive_hostname' => '{host}')

  # The options a profile used with the previous versions of the module
  legacy_params = {
    source_directories: ['/etc', '/home'],
    repositories: [{ 'path' => 'ssh://borg-12345@backup.example.org/mnt/backup/borgmatic_client1', 'label' => 'backup' }],
    patterns: ['R /'],
    exclude_patterns: ['*.glusterfs', '/var/cache/apt'],
    read_special: true,
    encryption_passphrase: RSpec::Puppet::Sensitive.new('secret'),
    ssh_command: 'ssh -i /root/.ssh/id_rsa_client1',
    umask: '0027',
    lock_wait: 120,
    relocated_repo_access_is_ok: true,
    extra_borg_options: { 'create' => '--noacls --noxattrs' },
    keep_hourly: 24,
    keep_daily: 15,
    keep_weekly: 12,
    keep_monthly: 18,
    checks: [{ 'name' => 'repository', 'frequency' => '4 weeks', 'only_run_on' => ['Saturday'] }],
    before_backup: ['/usr/local/bin/create_snapshot_symlink /mnt/cephfs'],
    after_backup: ['python3 /usr/local/bin/create_backup_error_logs.py append_success -p /var/log/borgmatic/client1_error.info'],
    on_error: ['python3 /usr/local/bin/create_backup_error_logs.py append_error -p /var/log/borgmatic/client1_error.info -f "{configuration_filename}" -r "{repository}" -o "{output}"'],
    after_everything: ['/usr/local/bin/clean_snapshot_symlink /mnt/cephfs'],
    mariadb_databases: [{ 'name' => 'all', 'username' => 'backup', 'password' => 'secret' }],
    healthchecks: 'https://hc-ping.com/uuid',
  }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with a repository' do
        let(:params) { { repositories: ['ssh://borg@backup.example.org/srv/borg/system'] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('borgmatic') }

        it do
          is_expected.to contain_file(path)
            .with_ensure('file')
            .with_owner('root')
            .with_group('root')
            .with_mode('0600')
            .with_validate_cmd('/usr/bin/borgmatic --config % --log-file /dev/null config validate')
            .with_content(%r{\A# Managed by Puppet\n---\n})
            .that_requires(['Class[borgmatic::install]', 'File[/etc/borgmatic.d]'])
        end

        it 'only renders the repository, as a hash' do
          expect(rendered_config(path)).to eq('repositories' => [{ 'path' => 'ssh://borg@backup.example.org/srv/borg/system' }])
        end
      end

      context 'with every option' do
        let(:params) { full_params }

        it { is_expected.to compile.with_all_deps }

        it 'renders every option in the order of the borgmatic reference' do
          expect(rendered_config(path)).to eq(full_config)
          expect(rendered_config(path).keys).to eq(full_config.keys)
        end

        it 'keeps long values on one line' do
          expect(rendered_content(path)).to include(%(- echo "{configuration_filename}" "{repository}" "{output}"\n))
        end

        it 'hides the content holding Sensitive values' do
          expect(catalogue.resource('File', path).sensitive_parameters).to include(:content)
        end
      end

      context 'with a Sensitive passphrase' do
        let(:params) { { repositories: ['/srv/borg/system'], encryption_passphrase: sensitive('pass: "word"') } }

        it { is_expected.to contain_file(path).with_content(sensitive(%r{encryption_passphrase})) }
        it { expect(rendered_config(path)['encryption_passphrase']).to eq('pass: "word"') }
      end

      context 'with a plain passphrase' do
        let(:params) { { repositories: ['/srv/borg/system'], encryption_passphrase: 'secret' } }

        it { expect(catalogue.resource('File', path).sensitive_parameters).not_to include(:content) }
      end

      context 'with options overriding parameters' do
        let(:params) do
          {
            repositories: ['/srv/borg/system'],
            keep_daily: 7,
            options: { 'keep_daily' => 14, 'bootstrap' => { 'store_config_files' => false } },
          }
        end

        it do
          expect(rendered_config(path)).to eq(
            'repositories' => [{ 'path' => '/srv/borg/system' }],
            'keep_daily' => 14,
            'bootstrap' => { 'store_config_files' => false },
          )
        end
      end

      context 'with the repositories in options' do
        let(:params) { { options: { 'repositories' => [{ 'path' => '/srv/borg/system' }] } } }

        it { is_expected.to compile.with_all_deps }
        it { expect(rendered_config(path)).to eq('repositories' => [{ 'path' => '/srv/borg/system' }]) }
      end

      context 'with hook settings given as hashes' do
        let(:params) do
          {
            repositories: ['/srv/borg/system'],
            healthchecks: { 'ping_url' => 'https://hc-ping.com/uuid', 'send_logs' => false },
            cronitor: { 'ping_url' => 'https://cronitor.link/d3x0c1' },
            pagerduty: { 'integration_key' => 'key', 'send_logs' => true },
          }
        end

        it do
          expect(rendered_config(path)).to include(
            'healthchecks' => { 'ping_url' => 'https://hc-ping.com/uuid', 'send_logs' => false },
            'cronitor' => { 'ping_url' => 'https://cronitor.link/d3x0c1' },
            'pagerduty' => { 'integration_key' => 'key', 'send_logs' => true },
          )
        end
      end

      context 'with a custom file' do
        let(:pre_condition) { "class { 'borgmatic': config_dir => '/etc/borgmatic', binary_path => '/root/.local/bin/borgmatic' }" }
        let(:params) do
          {
            repositories: ['/srv/borg/system'],
            path: '/etc/borgmatic.d/cephfs/volume1.yaml',
            owner: 'backup',
            group: 'backup',
            mode: '0640',
          }
        end

        it do
          is_expected.to contain_file('/etc/borgmatic.d/cephfs/volume1.yaml')
            .with_owner('backup')
            .with_group('backup')
            .with_mode('0640')
            .with_validate_cmd('/root/.local/bin/borgmatic --config % --log-file /dev/null config validate')
        end
      end

      context 'without validation' do
        let(:pre_condition) { "class { 'borgmatic': config_dir => '/etc/borgmatic' }" }
        let(:params) { { repositories: ['/srv/borg/system'], validate: false } }

        it { is_expected.to contain_file('/etc/borgmatic/system.yaml').without_validate_cmd }
      end

      context 'with ensure absent' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(path).with_ensure('absent').without_content }
      end

      context 'without repositories' do
        it { is_expected.to compile.and_raise_error(%r{at least one repository is required}) }
      end

      context 'with an invalid umask' do
        let(:params) { { repositories: ['/srv/borg/system'], umask: '27' } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'umask'}) }
      end

      context 'with an invalid check' do
        let(:params) { { repositories: ['/srv/borg/system'], checks: [{ 'name' => 'repository', 'frequncy' => '2 weeks' }] } }

        it { is_expected.to compile.and_raise_error(%r{parameter 'checks'}) }
      end
    end
  end

  context 'validated by borgmatic' do
    let(:facts) { on_supported_os.values.first }

    context 'with every option' do
      let(:params) { full_params }

      it { expect_valid_for_borgmatic(rendered_content(path), min_version: '2.1.0') }
    end

    context 'with the options of the previous versions of the module' do
      let(:params) { legacy_params }

      # only_run_on appeared in borgmatic 1.8.13
      it { expect_valid_for_borgmatic(rendered_content(path), min_version: '1.8.13') }
    end

    context 'with a repository' do
      let(:params) { { repositories: ['ssh://borg@backup.example.org/srv/borg/system'] } }

      it { expect_valid_for_borgmatic(rendered_content(path)) }
    end
  end
end
