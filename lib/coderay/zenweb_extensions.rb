require 'coderay'

require "coderay/scanners/elisp"
require "coderay/scanners/scheme"

::CodeRay::FileType::TypeFromExt['scm'] = :scheme
::CodeRay::FileType::TypeFromExt['el']  = :elisp
