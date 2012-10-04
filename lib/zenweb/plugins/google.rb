class Zenweb::Page
  ##
  # Returns a javascript blob to add a google ad to the page. You need
  # to provide the configuration param "google_ad_client" to your site
  # config for this to work.

  def google_ad slot, width = 468, height = 60
    <<-"EOM".gsub(/^ {6}/, '')
      <script><!--
      google_ad_client = "#{self["google_ad_client"]}";
      google_ad_slot   = "#{slot}";
      google_ad_width  = #{width};
      google_ad_height = #{height};
      //-->
      </script>
      <script src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
      </script>
    EOM
  end

  def google_analytics
    if site.config["google_ua"] then
      <<-"EOM".gsub(/^ {8}/, '')
        <script type="text/javascript">
          var _gaq = _gaq || [];
          _gaq.push(['_setAccount', '#{site.google_ua}']);
          _gaq.push(['_trackPageview']);

          (function() {
          var ga = document.createElement('script');
          ga.type = 'text/javascript';
          ga.async = true;
          ga.src = ('https:' == document.location.protocol ?
                    'https://ssl' : 'http://www') +
                   '.google-analytics.com/ga.js';
          (document.getElementsByTagName('head')[0] ||
           document.getElementsByTagName('body')[0]).appendChild(ga);
          })();
        </script>
      EOM
    end
  end

  def gauges_analytics
    if site.config["gauges_id"] then
      <<-"EOM".gsub(/^ {8}/, '')
        <script type="text/javascript">
          var _gauges = _gauges || [];
          (function() {
            var t   = document.createElement('script');
            t.type  = 'text/javascript';
            t.async = true;
            t.id    = 'gauges-tracker';
            t.setAttribute('data-site-id', '#{site.gauges_id}');
            t.src = '//secure.gaug.es/track.js';
            var s = document.getElementsByTagName('script')[0];
            s.parentNode.insertBefore(t, s);
          })();
        </script>
      EOM
    end
  end

  def analytics
    [google_analytics, gauges_analytics].compact.join "\n\n"
  end
end # google
