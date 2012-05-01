import argparse
import paramiko
import json

parser = argparse.ArgumentParser()
parser.add_argument("--host", dest="host", default="review.openstack.org",
                    help="gerrit host to connect to")
parser.add_argument("--port", dest="port", action='store', type=int,
                    default=29418, help="gerrit port to connect to")
parser.add_argument("groups", nargs=1)

options = parser.parse_args()


client = paramiko.SSHClient()
client.load_system_host_keys()
client.set_missing_host_key_policy(paramiko.WarningPolicy())
client.connect(options.host, port=options.port)

group = options.groups[0]
query = "select group_uuid from account_groups where name = '%s'" % group
command = 'gerrit gsql --format JSON -c "%s"' % query
stdin, stdout, stderr = client.exec_command(command)

for line in stdout:
    row = json.loads(line)
    if row['type'] == 'row':
        print row['columns']['group_uuid']
    ret = stdout.channel.recv_exit_status()
