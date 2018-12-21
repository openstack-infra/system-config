import argparse
import sys

import openstack


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--cloud", dest="cloud", required=True,
        help="cloud name")
    parser.add_argument(
        "--region", dest="region", required=True,
        help="cloud region")

    options = parser.parse_args()

    cloud_region = openstack.config.OpenStackConfig().get_one(
        cloud=options.cloud, region_name=options.region)

    print("export OS_REGION_NAME='{region_name}'".format(
        region_name=cloud_region.region_name))
    for k, v in cloud_region.auth.items():
        print("export OS_{key}='{value}'".format(
            key=k.upper(),
            value=v))
    return 0

if __name__ == '__main__':
    sys.exit(main())
