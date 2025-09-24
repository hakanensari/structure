# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"

  library "pathname"
  library "fileutils"

  configure_code_diagnostics(D::Ruby.lenient)
end

target :fixtures do
  signature "sig"
  signature "test/fixtures"
  check "test/fixtures/*.rb"
end
