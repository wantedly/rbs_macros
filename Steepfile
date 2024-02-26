D = Steep::Diagnostic

target :lib do
  signature "sig"

  check "lib"
  configure_code_diagnostics(D::Ruby.strict)
  # configure_code_diagnostics(D::Ruby.lenient)      # `lenient` diagnostics setting
  # configure_code_diagnostics(D::Ruby.silent)       # `silent` diagnostics setting
  # configure_code_diagnostics do |hash|             # You can setup everything yourself
  #   hash[D::Ruby::NoMethod] = :information
  # end
end

target :test do
  signature "sig", "sig-private"

  check "test"
  configure_code_diagnostics(D::Ruby.strict)
end
