module CodeRay
  module Scanners
    load :clojure

    class Scheme < Clojure

      register_for :scheme
      file_extension 'scm'
    end
  end
end
