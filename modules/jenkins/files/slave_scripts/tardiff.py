#!/usr/bin/python

# tardiff.py -- compare the tar package with git archive. Error out if
# it's different.  The files to exclude are stored in a file, one per line,
# and it's passed as argument to this script.
#
# You should run this script from the project directory. For example, if
# you are verifying the package for glance project, you should run this
# script from that directory.

import getopt
import sys
import os
import commands


class OpenStackTarDiff:
    """ main class to verify tar generated in each openstack projects """

    def __init__(self):
        self.init_vars()
        self.validate_args()
        self.check_env()

    def check_env(self):
        """ exit if dist/ directory already exists """
        if not self.package and os.path.exists(self.dist_dir):
            self.error(
                "dist directory '%s' exist. Please remove it before "
                "running this script" % self.dist_dir)

    def validate_args(self):
        try:
            opts = getopt.getopt(sys.argv[1:], 'hvp:e:',
                                 ['help', 'verbose', 'package=',
                                  'exclude='])[0]
        except getopt.GetoptError:
            self.usage('invalid option selected')

        for opt, value in opts:
            if (opt in ('-h', '--help')):
                self.usage()
            elif (opt in ('-e', '--exclude')):
                self.e_file = value
            elif (opt in ('-p', '--package')):
                self.package = value
            elif (opt in ('-v', '--verbose')):
                self.verbose = True
            else:
                self.usage('unknown option : ' + opt)
        if not self.e_file:
            self.usage('specify file name containing list of files to '
                       'exclude in tar diff')
        if not os.path.exists(self.e_file):
            self.usage("file '%s' does not exist" % self.e_file)
        if self.package and not os.path.exists(self.package):
            self.usage("package '%s' specified, but does not "
                       "exist" % self.package)

    def init_vars(self):
        self.dist_dir = 'dist/'
        self.verbose = False

        self.e_file = None
        self.project_name = None
        self.prefix = None
        self.package = None
        self.sdist_files = []
        self.exclude_files = []
        self.git_files = []
        self.missing_files = []

    def verify(self):
        self.get_exclude_files()
        self.get_project_name()
        self.get_sdist_files()
        self.prefix = self.sdist_files[0]
        self.get_git_files()

        for file in self.git_files:
            if os.path.basename(file) in self.exclude_files:
                self.debug("excluding file '%s'" % file)
                continue

            if file not in self.sdist_files:
                self.missing_files.append(file)
            else:
                #self.debug("file %s matches" % file)
                pass
        if len(self.missing_files) > 0:
            self.error("files missing in package: %s" % self.missing_files)
        print "SUCCESS: Generated package '%s' is valid" % self.package

    def get_project_name(self):
        """ get git project name """
        self.project_name = os.path.basename(os.path.abspath(os.curdir))

    def get_exclude_files(self):
        """ read the file and get file list """
        fh = open(self.e_file, 'r')
        content = fh.readlines()
        fh.close()
        self.debug("files to exclude: %s" % content)

        # remove trailing new lines.
        self.exclude_files = [x.strip() for x in content]

    def get_git_files(self):
        """ read file list from git archive """
        git_tar = os.path.join(os.getcwd(), '%s.tar' % self.project_name)
        try:
            a_cmd = ("git archive -o %s HEAD --prefix=%s" %
                     (git_tar, self.prefix))
            self.debug("executing command '%s'" % a_cmd)
            (status, out) = commands.getstatusoutput(a_cmd)
            if status != 0:
                self.debug("command '%s' returned status '%s'" %
                           (a_cmd, status))
                if os.path.exists(git_tar):
                    os.unlink(git_tar)
                self.error('git archive failed: %s' % out)
        except Exception as err:
            if os.path.exists(git_tar):
                os.unlink(git_tar)
            self.error('git archive failed: %s' % err)

        try:
            tar_cmd = "tar tf %s" % git_tar
            self.debug("executing command '%s'" % tar_cmd)
            (status, out) = commands.getstatusoutput(tar_cmd)
            if status != 0:
                self.error('invalid tar file: %s' % git_tar)
            self.git_files = out.split('\n')
            self.debug("Removing git archive ... %s ..." % git_tar)
            os.remove(git_tar)
        except Exception as err:
            self.error('unable to read tar: %s' % err)

    def get_sdist_files(self):
        """ create package for project and get file list in it"""
        if not self.package:
            try:
                sdist_cmd = "python setup.py sdist"
                self.debug("executing command '%s'" % sdist_cmd)
                (status, out) = commands.getstatusoutput(sdist_cmd)
                if status != 0:
                    self.error("command '%s' failed" % sdist_cmd)
            except Exception as err:
                self.error("command '%s' failed" % (sdist_cmd, err))

            self.package = os.listdir(self.dist_dir)[0]
            self.package = os.path.join(self.dist_dir, self.package)
        tar_cmd = "tar tzf %s" % self.package
        try:
            self.debug("executing command '%s'" % tar_cmd)
            (status, out) = commands.getstatusoutput(tar_cmd)
            if status != 0:
                self.error("command '%s' failed" % tar_cmd)
            #self.debug(out)
            self.sdist_files = out.split('\n')
        except Exception as err:
            self.error("command '%s' failed: %s" % (tar_cmd, err))

    def debug(self, msg):
        if self.verbose:
            sys.stdout.write('DEBUG: %s\n' % msg)

    def error(self, msg):
        sys.stderr.write('ERROR: %s\n' % msg)
        sys.exit(1)

    def usage(self, msg=None):
        if msg:
            stream = sys.stderr
        else:
            stream = sys.stdout
        stream.write("usage: %s [--help|h] [-v] "
                     "[-p|--package=sdist_package.tar.gz] "
                     "-e|--exclude=filename\n" % os.path.basename(sys.argv[0]))
        if msg:
            stream.write("\nERROR: " + msg + "\n")
            exitCode = 1
        else:
            exitCode = 0
        sys.exit(exitCode)

if __name__ == '__main__':
    tardiff = OpenStackTarDiff()
    tardiff.verify()
