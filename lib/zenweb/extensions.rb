def File.each_parent dir, file
  until dir == "." do
    dir = File.dirname dir
    yield File.join(dir, file).sub(/^\.\//, "")
  end
end

class Time
  def clean fmt = "%Y-%m-%d @ %H:%M"
    strftime fmt
  end
end
