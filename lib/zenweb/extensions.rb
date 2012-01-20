def File.each_parent dir, file
  until dir == "." do
    dir = File.dirname dir
    yield File.join(dir, file).sub(/^\.\//, "")
  end
end

class Time
  def date
    strftime "%Y-%m-%d"
  end

  def datetime
    strftime "%Y-%m-%d @ %H:%M"
  end

  def time
    strftime "%H:%M"
  end
end

gem "rake"
require 'rake'

class Rake::FileTask
  alias old_needed? needed?
  alias old_timestamp timestamp

  def needed?
    ! File.exist?(name) || timestamp > real_timestamp
  end

  def real_timestamp
    File.exist?(name) && File.mtime(name.to_s) || Rake::EARLY
  end

  def timestamp
    if File.exist?(name)
      a = File.mtime(name.to_s)
      b = super unless prerequisites.empty?
      [a, b].compact.max
    else
      Rake::EARLY
    end
  end
end
