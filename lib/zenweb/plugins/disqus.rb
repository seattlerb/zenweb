class Zenweb::Page
  def disqus shortname
    '<div id="disqus_thread"></div>' +
      run_js_script("http://#{shortname}.disqus.com/embed.js")
  end

  def disqus_counts shortname
    run_js_script "http://#{shortname}.disqus.com/count.js"
  end
end
