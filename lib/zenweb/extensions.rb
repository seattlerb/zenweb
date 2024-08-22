##
# Walk each parent directory of dir looking for file. Yield each file
# found to caller.

def File.each_parent dir, file
  until dir == "." do
    dir = File.dirname dir
    yield File.join(dir, file).sub(/^\.\//, "")
  end
end

module Enumerable
  def multi_group_by
    r = Hash.new { |h,k| h[k] = [] }
    each do |o|
      Array(yield(o)).each do |k|
        r[k] << o
      end
    end
    r
  end
end

class Array # :nodoc:
  def deep_each(depth = 0, &b) # :nodoc:
    return self.to_enum(:deep_each) unless b

    each do |x|
      case x
      when Array then
        x.deep_each(depth + 1, &b)
      else
        yield depth, x
      end
    end
  end
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
