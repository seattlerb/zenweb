require 'haml'

class Zenweb::Page

  ##
  # Render haml page content using Haml.

  def render_haml page, content
    haml(content || page.body)
  end

  def haml content
    ::Haml::Engine.new(content).render
  end

end
