# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::RepositoryEntry' do
  it do
    is_expected.to allow_values(
      'ssh://borg@backup.example.org/srv/borg/client1',
      { 'path' => '/srv/borg/client1' },
      { 'path' => '/srv/borg/client1', 'label' => 'local', 'encryption' => 'repokey-blake2', 'append_only' => true, 'storage_quota' => '5G', 'make_parent_directories' => true },
    )
  end

  it { is_expected.not_to allow_values('', { 'label' => 'local' }, { 'path' => '/srv/borg/client1', 'lable' => 'local' }, nil) }
end
