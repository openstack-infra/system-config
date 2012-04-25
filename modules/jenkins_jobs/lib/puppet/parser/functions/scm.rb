module Puppet::Parser::Functions
  newfunction(:scm, :type => :rvalue) do |args|
    file = "jenkins_jobs/scm_" + args[0] + ".xml.erb"
    wrapper = Puppet::Parser::TemplateWrapper.new(self)
    wrapper.file = file
      begin
        wrapper.result
      rescue => detail
        raise Puppet::ParseError,
          "Failed to parse template #{file}: #{detail}"
      end
  end
end
