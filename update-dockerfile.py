#!/usr/bin/python3
import re
from argparse import ArgumentParser

import requests


def log(msg):
    print(msg, flush=True, end="")


def logline(msg):
    print(msg, flush=True)


def update_mantis(t: str, mantis_version: str) -> str:
    m = re.match(r"^[0-9.]+$", mantis_version)
    assert m
    version = m.group(0)

    log(f"Get SHA1 digest for {version}...")
    url_fmt = "https://master.dl.sourceforge.net/project/mantisbt/mantis-stable/{MANTIS_VER}/mantisbt-{MANTIS_VER}.tar.gz.digests"
    url = url_fmt.format(MANTIS_VER=version)

    resp = requests.get(url)
    assert resp.status_code == 200, f"Invalid status code {resp.status_code}"
    m = re.search(r"([0-9a-f]{128}) ", resp.text)
    assert m, resp.text
    sha512 = m.group(1)
    logline(sha512)

    m = re.search(r"MANTIS_VER=([0-9.]+)", t)
    assert m
    t_new = t[: m.start(1)] + version
    t = t[m.end(0) :]

    m = re.search(r"MANTIS_SHA512=([0-9a-f]+)", t)
    assert m
    t_new += t[: m.start(1)] + sha512
    t_new += t[m.end(0) :]

    return t_new


def parse_tag_version(tag_name: str) -> tuple:
    r = re.compile("^([0-9]+)[.]([0-9]+)[.]([0-9]+)-apache$")

    m = r.match(tag_name)
    if m is None:
        return None

    major = int(m.group(1))
    minor = int(m.group(2))
    patch = int(m.group(3))

    return (major, minor, patch)


def update_php(t: str) -> str:
    names = {}
    log("Get latest PHP image tag...")
    # supported tags of the official image, one request
    url = "https://raw.githubusercontent.com/docker-library/official-images/master/library/php"
    resp = requests.get(url)
    assert resp.status_code == 200, f"Invalid status code {resp.status_code}"

    for line in resp.text.splitlines():
        if not line.startswith("Tags:"):
            continue

        for name in line[len("Tags:") :].split(","):
            name = name.strip()
            tag_version = parse_tag_version(name)
            if tag_version is None:
                continue

            names[tag_version] = name

    assert names, "No X.Y.Z-apache tag found in " + url

    latest_version = max(names.keys())
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
        log(
            f"WARNING: current tag {current_tag_name} is newer than latest {latest_tag_name} "
        )

    t = t[: m.start(1)] + latest_tag_name + t[m.end(1) :]

    return t


def update_readme(t: str, dockerfile: str) -> str:
    # sync version badges with Dockerfile
    m = re.search(r"MANTIS_VER=([0-9.]+)", dockerfile)
    assert m
    t = re.sub(r"(badge/MantisBT-)[0-9.]+(-)", r"\g<1>" + m.group(1) + r"\g<2>", t)

    m = re.search(r"FROM php:([0-9]+[.][0-9]+)", dockerfile)
    assert m
    t = re.sub(r"(badge/PHP-)[0-9.]+(-)", r"\g<1>" + m.group(1) + r"\g<2>", t)

    return t


def patch_file(filepath: str, t_new: str, t_old: str):
    if t_new == t_old:
        logline("Unchanged")
    else:
        with open(filepath, "w") as file:
            file.write(t_new)
        logline("Updated")


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument(
        "--mantis-version",
        help="Update to this mantis version, will also update the SHA",
    )
    parser.add_argument(
        "--keep-php-version",
        action="store_true",
        default=False,
        help="Do not try to find the latest PHP version",
    )

    args = parser.parse_args()

    filepath = "Dockerfile"
    log(f"Patch {filepath}...")
    with open(filepath, "r") as file:
        t = file.read()

    t_old = t

    if args.mantis_version is not None:
        t = update_mantis(t, args.mantis_version)

    if not args.keep_php_version:
        t = update_php(t)

    patch_file(filepath, t, t_old)

    readme_path = "README.md"
    log(f"Patch {readme_path}...")
    with open(readme_path, "r") as file:
        r_old = file.read()
    patch_file(readme_path, update_readme(r_old, t), r_old)
