require_relative 'test_helper'

require 'text_mate_mock'
require 'rails/rails_path'

# TextMate.open navigates between project files (the Go To commands). It
# prefers the running application's own mate binary (TM_MATE) so navigation
# stays in the app that invoked the command; the txmt:// URL scheme goes
# through LaunchServices, which routes to whichever installed TextMate owns
# the scheme and opened the wrong application on dual-install machines.
class TextMateOpenTest < Test::Unit::TestCase
  def setup
    @original_env = ENV.to_hash
  end

  def teardown
    ENV.replace(@original_env)
  end

  def test_mate_open_command_uses_the_running_applications_mate
    ENV['TM_MATE'] = '/Applications/Built.app/Contents/MacOS/mate'
    expected = ['/Applications/Built.app/Contents/MacOS/mate', '--line=11:3', 'app/models/user.rb']
    assert_equal(expected, TextMate.mate_open_command('app/models/user.rb', 10, 2))
  end

  def test_mate_open_command_without_a_position
    ENV['TM_MATE'] = '/Applications/Built.app/Contents/MacOS/mate'
    expected = ['/Applications/Built.app/Contents/MacOS/mate', 'app/models/user.rb']
    assert_equal(expected, TextMate.mate_open_command('app/models/user.rb'))
  end

  def test_open_falls_back_to_the_txmt_url_scheme_without_tm_mate
    ENV.delete('TM_MATE')
    # The mock's open_url returns the command string instead of running it.
    result = TextMate.open('/foo/bar.rb', 0)
    assert_equal(%q{open "txmt://open?url=file:///foo/bar.rb&line=1"}, result)
  end
end
