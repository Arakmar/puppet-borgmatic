# frozen_string_literal: true

require 'open3'
require 'tempfile'
require 'yaml'

# Helpers reading the borgmatic configuration files of the catalogue and
# checking them with borgmatic itself when it is installed.
module BorgmaticSpecHelpers
  # The borgmatic executable checking the rendered files: $BORGMATIC or the
  # one found in the PATH, nil when it is not an executable.
  def self.borgmatic
    @borgmatic ||= if ENV['BORGMATIC']
                     ENV['BORGMATIC'] if File.executable?(ENV['BORGMATIC'])
                   else
                     ENV['PATH'].split(File::PATH_SEPARATOR).map { |dir| File.join(dir, 'borgmatic') }.find { |path| File.executable?(path) }
                   end
  end

  def self.borgmatic_version
    return nil unless borgmatic

    @borgmatic_version ||= Gem::Version.new(Open3.capture2e(borgmatic, '--version').first.strip)
  end

  # Raw content of a file resource, unwrapped when it is Sensitive.
  def rendered_content(path)
    content = catalogue.resource('File', path)[:content]
    content.respond_to?(:unwrap) ? content.unwrap : content
  end

  # Content of a file resource, parsed as YAML.
  def rendered_config(path)
    YAML.safe_load(rendered_content(path))
  end

  # Whether the installed borgmatic is at least `release`
  def self.at_least?(release)
    !borgmatic_version.nil? && borgmatic_version >= Gem::Version.new(release)
  end

  # Checks a configuration like borgmatic::config does.
  def expect_valid_for_borgmatic(content)
    raise 'borgmatic not found' if BorgmaticSpecHelpers.borgmatic.nil?

    Tempfile.create(['borgmatic', '.yaml']) do |file|
      file.write(content)
      file.flush
      output, status = Open3.capture2e(BorgmaticSpecHelpers.borgmatic, '--config', file.path, '--log-file', File::NULL, 'config', 'validate')
      expect(status).to be_success, output
    end
  end
end

RSpec.configure do |c|
  c.include BorgmaticSpecHelpers
  # The checks, tagged :borgmatic, are left out rather than skipped one by one
  # without borgmatic: the CI jobs installing borgmatic run them. With
  # BORGMATIC_VALIDATE a missing borgmatic fails them instead.
  c.filter_run_excluding(:borgmatic) unless ENV['BORGMATIC_VALIDATE'] || BorgmaticSpecHelpers.borgmatic
  # Those needing a newer borgmatic than the installed one are left out too.
  # This is another key than the tag, which --tag would override.
  c.filter_run_excluding borgmatic_release: ->(release) { BorgmaticSpecHelpers.borgmatic && !BorgmaticSpecHelpers.at_least?(release) }
end
