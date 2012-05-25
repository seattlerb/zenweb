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
