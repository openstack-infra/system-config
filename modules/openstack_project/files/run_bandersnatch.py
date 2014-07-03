import logging
import requests
import subprocess

logger = logging.getLogger('bandersnatch')


def setup_logging():
    ch = logging.StreamHandler()
    formatter = logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s')
    ch.setFormatter(formatter)
    logger.setLevel(logging.INFO)
    logger.addHandler(ch)

def main():
    stale=dict()
    output = subprocess.check_output(
        ['bandersnatch', 'mirror'], stderr=subprocess.STDOUT) 
    for line in output.split('\n'):
        print(line)
        if 'Expected PyPI serial' in line:
            url = line.split("for request ")[1].split()[0]
            stale[url] = True
    for url in stale.keys():
        logger.info('Purging %s' % url)
        response = requests.request('PURGE', url)
        if not response.ok:
            logger.error('Failed to purge %s: %s' % (url, response.text))


if __name__ == '__main__':
    main()
