class Zenweb::Page

  ##
  # Returns a javascript blob to add a disqus comments block to the page.

  def disqus shortname
    '<div id="disqus_thread"></div>' +
      run_js_script("http://#{shortname}.disqus.com/embed.js")
  end

  ##
  # Returns a javascript blob to convert properly formatted links to
  # disqus comment counts.

  def disqus_counts shortname
    run_js_script "http://#{shortname}.disqus.com/count.js"
  end
end
