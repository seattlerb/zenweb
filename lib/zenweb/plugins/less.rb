class Zenweb::Page
  ##
  # Render less source to css.

  def render_less page, content
    require "less"

    Less::Engine.new(content || body).to_css
  end
end
