# frozen_string_literal: true

require 'spec_helper'

describe 'Borgmatic::Command' do
  it do
    is_expected.to allow_values(
      { 'before' => 'action', 'when' => ['create', 'prune'], 'run' => ['echo before'] },
      { 'before' => 'everything', 'run' => ['echo start'] },
      { 'after' => 'error', 'run' => ['echo "{error}"'] },
      { 'after' => 'repository', 'when' => ['check'], 'states' => ['finish', 'fail'], 'run' => ['echo done'] },
    )
  end

  it do
    is_expected.not_to allow_values(
      { 'before' => 'error', 'run' => ['echo'] },
      { 'before' => 'action', 'states' => ['fail'], 'run' => ['echo'] },
      { 'after' => 'action', 'when' => ['backup'], 'run' => ['echo'] },
      { 'after' => 'action', 'run' => [] },
      { 'before' => 'action', 'after' => 'action', 'run' => ['echo'] },
      { 'run' => ['echo'] },
    )
  end
end
