class Zenweb::Page
  def render_less page, content
    require "less"
    Less::Engine.new(body).to_css
  end
end # less
