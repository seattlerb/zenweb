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
end # google
