# frozen_string_literal: true

require 'open3'
require 'tempfile'
require 'yaml'

# Helpers reading the borgmatic configuration files of the catalogue and
# checking them with borgmatic itself when it is installed.
module BorgmaticSpecHelpers
  # The borgmatic executable checking the rendered files: $BORGMATIC or the
  # one found in the PATH. With BORGMATIC_VALIDATE set, a missing borgmatic
  # fails these examples instead of skipping them.
  def self.borgmatic
    @borgmatic ||= ENV['BORGMATIC'] || ENV['PATH'].split(File::PATH_SEPARATOR).map { |dir| File.join(dir, 'borgmatic') }.find { |path| File.executable?(path) }
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

  # Checks a configuration like borgmatic::config does, skipping the example
  # when borgmatic is missing or older than min_version.
  def expect_valid_for_borgmatic(content, min_version: '1.8.0')
    if BorgmaticSpecHelpers.borgmatic.nil?
      raise 'borgmatic not found' if ENV['BORGMATIC_VALIDATE']

      skip 'borgmatic is not installed'
    end
    skip "borgmatic #{BorgmaticSpecHelpers.borgmatic_version} is older than #{min_version}" if BorgmaticSpecHelpers.borgmatic_version < Gem::Version.new(min_version)

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
end
