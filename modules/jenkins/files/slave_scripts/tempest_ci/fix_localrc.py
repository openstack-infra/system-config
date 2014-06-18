import netifaces
import re
import shutil

def _replaces_in_file(file, replacement_list):
    rs = [ (re.compile(regexp), repl) for (regexp, repl) in replacement_list]
    file_tmp = file + ".tmp"
    with open(file, 'r') as f:
        with open(file_tmp, 'w') as f_tmp:
            for line in f:
                for r, replace in rs:
                    match = r.search(line)
                    if match:
                        line = replace + "\n"
                f_tmp.write(line)
    shutil.move(file_tmp, file)

def replace_in_file(file, regexp, replace):
    _replaces_in_file(file, [(regexp, replace)])

addrs = netifaces.ifaddresses('eth0')
local_ip=addrs[netifaces.AF_INET][0]['addr']

replace_in_file('/home/jenkins/devstack/localrc', 'HOST_IP=', 'HOST_IP=' + local_ip)


