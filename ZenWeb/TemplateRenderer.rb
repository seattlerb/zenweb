# this is a simple template. Globally replace Template with the name of
# your renderer and then go fill in YYY with the appropriate content.

require 'ZenWeb/GenericRenderer'
require 'ZenWeb/MetadataRenderer'

=begin

= Class TemplateRenderer

Reads in a template file named in the 'template' metadata variable, or
grabs 'template_content' (mainly for testing purposes).

=== Methods

=end

class TemplateRenderer < GenericRenderer

=begin

     --- TemplateRenderer#render(content)

     

=end

  def render(content)
    template_content = @document['TEMPLATE_CONTENT']

    unless template_content then
      path = @document['TEMPLATE'] or raise "Neither TEMPLATE_CONTENT nor TEMPLATE were defined"
      template_content = File.new(path).read
    end

    # HACK - this is copied here from HtmlTemplateRenderer for my own reference
#     author      = @document['author']
#     banner      = @document['banner']
#     bgcolor     = @document['bgcolor']
#     charset     = @document['charset']
#     copyright   = @document['copyright']
#     description = @document['description']
#     dtd         = @document['dtd'] || 'DTD HTML 4.01'
#     email       = @document['email']
#     icbm        = @document['icbm']
#     keywords    = @document['keywords']
#     lang        = @document['lang'] || 'en'
#     rating      = @document['rating'] || 'general'
#     style       = @document['style']
#     stylesheet  = @document['stylesheet']
#     subtitle    = @document['subtitle']
#     title       = @document.title
#     icbm_title  = @document['icbm_title'] || title
#     titletext   = @document.fulltitle

    @document.default 'LANG', 'en'
    @document.default 'DTD_VER', 'DTD HTML 4.01'
    @document.default 'DTD_URL', 'http://www.w3.org/TR/html4/strict.dtd'
    @document.default 'DOCTYPE', "<!DOCTYPE HTML PUBLIC \"-//W3C//#{@document['DTD_VER']}//EN\" \"#{@document['DTD_URL']}\">"
    @document.default 'RATING', 'general'
    @document.default 'ICBM_TITLE', @document.title
    @document.default 'FULLTITLE', @document.fulltitle
    @document.default 'TITLE', @document['TITLE']
    @document.default 'BODY', content

    content = template_content.gsub(/\#\{BODY\}/, content)
    content = MetadataRenderer.new(@document).render(content) # HACK

    push content

    return self.result
  end

end
