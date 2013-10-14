module CodeRay
  module Scanners
    load :clojure

    class Elisp < Clojure

      register_for :elisp
      file_extension 'el'
    end
  end
end
