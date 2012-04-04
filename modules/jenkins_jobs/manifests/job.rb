# workaround for http://projects.puppetlabs.com/issues/5237
pundef ||= Puppet::Parser::AST::Leaf::Undef.new({:value => ''})

define "job", :site, :project, :job, :assigned_nodes, :one_node, :builders, :triggers => pundef, :publishers => pundef, :logrotate => pundef, :scm => pundef do

  @assigned_nodes.each do |assigned_node|

    scope.unsetvar("assigned_node")
    scope.setvar("assigned_node", assigned_node)
    if @assigned_nodes.nitems == 1 or @one_node == 'true'
      assigned_node = ""
    else
      assigned_node = "#{assigned_node}-"
    end

    project = @project
    job = @job

    file "/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}",
      :ensure => :directory,
      :owner => 'jenkins'  

    file "/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}/builds",
      :ensure => :directory,
      :owner => 'jenkins',
      :require => "File[/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}]"

    file "/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}/config-history",
      :ensure => :directory,
      :owner => 'jenkins',
      :require => "File[/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}]"

    file "/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}/config.xml",
      :ensure => :present,
      :content => template("jenkins_jobs/body.xml.erb"),
      :owner => 'jenkins',
      :require => "File[/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}]",
      :notify => "Service[jenkins]"

    file "/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}/nextBuildNumber",
      :ensure => :present,
      :content => '1',
      :owner => 'jenkins',
      :replace => false,
      :require => "File[/var/lib/jenkins/jobs/#{project}-#{assigned_node}#{job}]"

    break if @one_node == 'true'

  end
end
