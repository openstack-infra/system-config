Facter.add("gerrit_installed") do
  setcode do
    FileTest.directory?("/home/gerrit2/review_site/")
  end
end
