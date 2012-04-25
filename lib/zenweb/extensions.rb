##
# Walk each parent directory of dir looking for file. Yield each file
# found to caller.

def File.each_parent dir, file
  until dir == "." do
    dir = File.dirname dir
    yield File.join(dir, file).sub(/^\.\//, "")
  end
end

class File # :nodoc:
  RUBY19 = "<3".respond_to? :encoding # :nodoc:

  class << self
    alias :binread :read unless RUBY19
  end
end

class String # :nodoc:
  def valid_encoding? # :nodoc:
    true
  end unless File::RUBY19
end

class Time # :nodoc:
  ##
  # Format as YYYY-MM-DD

  def date
    strftime "%Y-%m-%d"
  end

  def ym
    strftime "%Y-%m"
  end

  ##
  # Format as YYYY-MM-DD @ HH:MM

  def datetime
    strftime "%Y-%m-%d @ %H:%M"
  end

  ##
  # Format as HH:MM

  def time
    strftime "%H:%M"
  end
end

# :stopdoc:

gem "rake"
require 'rake'

module Rake
class FileTask
  alias old_needed? needed?
  alias old_timestamp timestamp

  def needed?
    ! File.exist?(name) || timestamp > real_timestamp
  end

  def real_timestamp
    File.exist?(name) && File.mtime(name.to_s) || Rake::EARLY
  end

  def timestamp
    @timestamp ||=
      if File.exist?(name)
        a = File.mtime(name.to_s)
        b = super unless prerequisites.empty?
        [a, b].compact.max
      else
        Rake::EARLY
      end
  end
end
end

# :startdoc:
