class Zenweb::LessPlugin < Zenweb::Renderer

  renders 'less'

  def process page, content
    render_less page, content
  end

  ##
  # Render less source to css.

  def render_less page, content
    require "less"

    Less::Engine.new(content || body).to_css
  end
end
