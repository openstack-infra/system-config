define process_projects($site) {
  exec { "jenkins_job_${name}":
    command => "python /usr/local/jenkins_jobs/jenkins_jobs.py update /usr/local/jenkins_jobs/projects/${site}/${name}.yml",
    cwd => '/usr/local/jenkins_jobs/',
    path => '/bin:/usr/bin'
  }

}
