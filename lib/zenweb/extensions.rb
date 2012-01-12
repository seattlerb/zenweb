def File.each_parent dir, file
  until dir == "." do
    dir = File.dirname dir
    yield File.join(dir, file).sub(/^\.\//, "")
  end
end

class Time
  def date
    clean "%Y-%m-%d"
  end

  def time
    clean "%H:%M"
  end

  def datetime
    clean "%Y-%m-%d @ %H:%M"
  end

  def clean fmt
    strftime fmt
  end
end
