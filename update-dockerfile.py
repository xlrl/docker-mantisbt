#!/usr/bin/python3
from argparse import ArgumentParser
import json
import requests
import re


def log(msg):
    print(msg, flush=True, end="")


def logline(msg):
    print(msg, flush=True)


def update_mantis(t : str, mantis_version : str) -> str:
    m = re.match(r"^[0-9.]+$", mantis_version)
    assert m
    version = m.group(0)

    log("Get SHA1 digest for %s..." % version)
    url_fmt = "https://master.dl.sourceforge.net/project/mantisbt/mantis-stable/{MANTIS_VER}/mantisbt-{MANTIS_VER}.tar.gz.digests"
    url = url_fmt.format(MANTIS_VER=version)

    resp = requests.get(url)
    assert resp.status_code == 200, "Invalid status code %d" % resp.status_code
    m = re.search(r"([0-9a-f]{128}) ", resp.text)
    assert m, resp.text
    sha512 = m.group(1)
    logline(sha512)

    m = re.search(r"MANTIS_VER ([0-9.]+)", t)
    assert m
    t_new = t[ : m.start(1)] + version
    t = t[m.end(0) : ]

    m = re.search(r"MANTIS_SHA512 ([0-9a-f]+)", t)
    assert m
    t_new += t[ : m.start(1)] + sha512
    t_new += t[m.end(0) : ]

    return t_new

def parse_tag_version(tag_name : str) -> tuple:
    r = re.compile("^([0-9]+)[.]([0-9]+)[.]([0-9]+)-apache$")

    m = r.match(tag_name)
    if m is None:
        return None

    major = int(m.group(1))
    minor = int(m.group(2))
    patch = int(m.group(3))

    return (major, minor, patch)


def update_php(t : str) -> str:
    names = {}
    log("Get latest PHP image tag...")
    for page in range(1, 20):
        url = f"https://hub.docker.com/v2/namespaces/library/repositories/php/tags?page_size=100&page={page}"
        resp = requests.get(url)

        assert resp.status_code == 200, "Invalid status code %d" % resp.status_code

        #print(resp.text)
        #with open("foo.json", "w") as file:
        #    file.write(resp.text)
        j = json.loads(resp.text)
        for result in j["results"]:
            name = result["name"]
            if not name.endswith("apache"):
                continue

            log(".")
 
            tag_version = parse_tag_version(name)
            if tag_version is None:
                continue

            names[tag_version] = name

    latest_version = sorted(names.keys())[-1]
    latest_tag_name = names[latest_version]
    log(latest_tag_name)
    log(" ")

    m = re.search(r"FROM php:([^\s]+)", t)
    assert m is not None
    current_tag_name = m.group(1)
    current_version = parse_tag_version(current_tag_name)

    if current_version is None:
        pass
    elif latest_version < current_version:
        log(f"WARNING: current tag {current_tag_name} is newer than latest {latest_tag_name} ")

    t = t[:m.start(1)] + latest_tag_name + t[m.end(1): ]

    return t



if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--mantis-version", help="Update to this mantis version, will also update the SHA")
    parser.add_argument("--keep-php-version", action="store_true", default=False, help="Do not try to find the latest PHP version")

    args = parser.parse_args()


    filepath = "Dockerfile"
    log("Patch %s..." % filepath)
    with open(filepath, "r") as file:
        t = file.read()

    t_old = t

    if args.mantis_version is not None:
        t = update_mantis(t, args.mantis_version)

    if not args.keep_php_version:
        t = update_php(t)

    if t == t_old:
        logline("Unchanged")
    else:
        with open(filepath, "w") as file:
            file.write(t)
        logline("Updated")
