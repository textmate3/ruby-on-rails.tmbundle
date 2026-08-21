# Copyright:
#   (c) 2006 syncPEOPLE, LLC.
#   Visit us at http://syncpeople.com/
# Author: Duane Johnson (duane.johnson@gmail.com)
# Description:
#   Helper module for accesing TextMate facilities such as environment variables.

require 'uri'
module TextMate
  class <<self
    def open_url(url)
      `open "#{url}"`
    end

    # Open a file in TextMate. Uses 0-based line and column indices.
    #
    # Prefers the running application's own mate binary (TM_MATE, set by
    # TextMate for every command) so navigation stays in the app that invoked
    # the command. The txmt:// URL scheme goes through LaunchServices, which
    # routes to whichever installed TextMate owns the scheme and opens the
    # wrong application on machines with more than one TextMate installed.
    def open(filename, line_number = nil, column_number = nil)
      filename = filename.filepath if filename.is_a? RailsPath
      if ENV['TM_MATE']
        system(*mate_open_command(filename, line_number, column_number))
      else
        options = []
        options << "url=file://#{URI::DEFAULT_PARSER.escape(filename)}"
        options << "line=#{line_number + 1}" if line_number
        options << "column=#{column_number + 1}" if column_number
        open_url "txmt://open?" + options.join("&")
      end
    end

    # The argv for opening a file via the running application's mate binary.
    def mate_open_command(filename, line_number = nil, column_number = nil)
      command = [ENV['TM_MATE']]
      if line_number
        selection = (line_number + 1).to_s
        selection += ":#{column_number + 1}" if column_number
        command << "--line=#{selection}"
      end
      command << filename
    end

    # Always return something, or nil, for selected_text
    def selected_text
      env(:selected_text)
    end

    # Make line_number 0-base index
    def line_number
      env(:line_number).to_i - 1
    end

    # Make column_number 0-base as well
    def column_number
      env(:column_number).to_i - 1
    end

    def project_directory
      env(:project_directory)
    end

    def env(var)
      ENV['TM_' + var.to_s.upcase]
    end

    # Forward to the TM_* environment variables if method is missing.  Some useful variables include:
    #   selected_text, current_line, column_number, line_number, support_path
    def method_missing(method, *args)
      if value = env(method)
        return value
      else
        super(method, *args)
      end
    end

    def cocoa_dialog_command
      "#{support_path}/bin/CocoaDialog.app/Contents/MacOS/CocoaDialog"
    end

    # See http://cocoadialog.sourceforge.net/documentation.html for documentation
    def cocoa_dialog(command, options = {})
      options_list = []
      options.each_pair do |k, v|
        k = k.to_s.gsub('_', '-')
        value = v.is_a?(Array) ? %Q{"#{v.join('" "')}"} : "\"#{v}\""
        if v
          if v.is_a? TrueClass
            options_list << "--#{k}"
          else
            options_list << "--#{k} #{value}"
          end
        end
      end
      dialog_command = "\"#{cocoa_dialog_command}\" #{command} #{options_list.join(' ')}"
      `#{dialog_command}`.split
    end

    def choose(text, choices = ["none"], options = {})
      options = {:title => "Choose", :text => text, :items => choices, :button1 => 'Ok', :button2 => 'Cancel'}.update(options)
      button, choice = cocoa_dialog('dropdown', options)
      if button == '1'
        return choice.strip.to_i
      else
        return nil
      end
    end
    
    def standard_choose(text, choices = ["none"], options = {})
      options = {:title => "Choose", :text => text, :items => choices, :button1 => 'Ok', :button2 => 'Cancel'}.update(options)
      cocoa_dialog('dropdown', options)
    end
  end
end
