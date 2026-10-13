# frozen_string_literal: true

require 'spec_helper'

describe 'borgmatic::timer' do
  let(:title) { 'system' }

  service = '/etc/systemd/system/borgmatic-system.service'
  timer = '/etc/systemd/system/borgmatic-system.timer'

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('borgmatic') }

        it 'runs the configuration of the same name with a low priority' do
          is_expected.to contain_systemd__manage_unit('borgmatic-system.service')
            .with_ensure('present')
            .without_enable
            .without_active
          is_expected.to contain_file(service)
            .with_content(%r{^Description=borgmatic backup system$})
            .with_content(%r{^Wants=network-online.target$})
            .with_content(%r{^After=network-online.target$})
            .with_content(%r{^Type=oneshot$})
            .with_content(%r{^ExecStart=/usr/bin/borgmatic --config /etc/borgmatic.d/system.yaml$})
            .with_content(%r{^Nice=19$})
            .with_content(%r{^CPUSchedulingPolicy=batch$})
            .with_content(%r{^IOSchedulingClass=best-effort$})
            .with_content(%r{^IOSchedulingPriority=7$})
        end

        it 'starts it daily, catching up missed runs' do
          is_expected.to contain_systemd__manage_unit('borgmatic-system.timer')
            .with_ensure('present')
            .with_enable(true)
            .with_active(true)
            .that_requires(['Systemd::Manage_unit[borgmatic-system.service]', 'Class[borgmatic::install]'])
          is_expected.to contain_file(timer)
            .with_content(%r{^OnCalendar=daily$})
            .with_content(%r{^Persistent=true$})
            .with_content(%r{^WantedBy=timers.target$})
            .without_content(%r{RandomizedDelaySec})
          is_expected.to contain_service('borgmatic-system.timer').with_ensure(true).with_enable(true)
        end
      end

      context 'with every option' do
        let(:pre_condition) { "class { 'borgmatic': binary_path => '/root/.local/bin/borgmatic' }" }
        let(:params) do
          {
            config: '/etc/borgmatic.d/cephfs',
            on_calendar: ['*-*-* 02:15:00', '*-*-* 14:15:00'],
            persistent: false,
            randomized_delay_sec: '30m',
            actions: ['create', 'prune'],
            verbosity: -1,
            syslog_verbosity: 1,
            log_file: '/var/log/borgmatic/cephfs.log',
            log_file_verbosity: 1,
            extra_args: ['--no-color'],
            nice: 10,
            cpu_scheduling_policy: 'idle',
            io_scheduling_class: 'idle',
            io_scheduling_priority: 0,
            unit_entry: { 'Documentation' => 'https://torsion.org/borgmatic/' },
            service_entry: { 'Nice' => '', 'TimeoutStartSec' => '6h' },
            timer_entry: { 'AccuracySec' => '1m' },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file(service)
            .with_content(%r{^Documentation=https://torsion.org/borgmatic/$})
            .with_content(
              Regexp.new(
                '^ExecStart=/root/.local/bin/borgmatic --verbosity -1 --syslog-verbosity 1 --log-file /var/log/borgmatic/cephfs.log ' \
                '--log-file-verbosity 1 --no-color --config /etc/borgmatic.d/cephfs create prune$',
              ),
            )
            .with_content(%r{^Nice=$})
            .with_content(%r{^CPUSchedulingPolicy=idle$})
            .with_content(%r{^IOSchedulingClass=idle$})
            .with_content(%r{^IOSchedulingPriority=0$})
            .with_content(%r{^TimeoutStartSec=6h$})
        end

        it do
          is_expected.to contain_file(timer)
            .with_content(%r{^OnCalendar=\*-\*-\* 02:15:00\nOnCalendar=\*-\*-\* 14:15:00$})
            .with_content(%r{^Persistent=false$})
            .with_content(%r{^RandomizedDelaySec=30m$})
            .with_content(%r{^AccuracySec=1m$})
        end
      end

      context 'with the timer disabled' do
        let(:params) { { enable: false } }

        it { is_expected.to contain_file(service).with_ensure('file') }
        it { is_expected.to contain_systemd__manage_unit('borgmatic-system.timer').with_ensure('present').with_enable(false).with_active(false) }
      end

      context 'with ensure absent' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(service).with_ensure('absent') }
        it { is_expected.to contain_file(timer).with_ensure('absent') }
        it { is_expected.to contain_service('borgmatic-system.timer').with_ensure(false).with_enable(false) }
      end
    end
  end
end
