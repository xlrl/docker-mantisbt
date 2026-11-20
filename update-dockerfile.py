#!/usr/bin/python3
import io
import re
import tarfile
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


ALPINE_URL = "https://dl-cdn.alpinelinux.org/alpine"


def latest_alpine_branch() -> str:
    url = f"{ALPINE_URL}/latest-stable/releases/x86_64/latest-releases.yaml"
    resp = requests.get(url)
    assert resp.status_code == 200, f"Invalid status code {resp.status_code}"
    m = re.search(r"branch: v([0-9]+[.][0-9]+)", resp.text)
    assert m, "No branch in " + url
    return m.group(1)


def latest_php_package(branch: str) -> str:
    # newest phpXY package in community
    url = f"{ALPINE_URL}/v{branch}/community/x86_64/APKINDEX.tar.gz"
    resp = requests.get(url)
    assert resp.status_code == 200, f"Invalid status code {resp.status_code}"
    with tarfile.open(fileobj=io.BytesIO(resp.content)) as tar:
        member = tar.extractfile("APKINDEX")
        assert member is not None
        index = member.read().decode()
    names = re.findall(r"^P:(php[0-9]{2})$", index, re.MULTILINE)
    assert names, "No phpXY package in " + url
    return max(names, key=lambda n: int(n[3:]))


def update_base(t: str) -> str:
    log("Get latest Alpine branch and PHP package...")
    branch = latest_alpine_branch()
    php = latest_php_package(branch)
    log(f"alpine:{branch} {php} ")

    m = re.search(r"FROM alpine:([0-9.]+)", t)
    assert m is not None
    current = tuple(int(x) for x in m.group(1).split("."))
    if tuple(int(x) for x in branch.split(".")) < current:
        log(f"WARNING: current alpine:{m.group(1)} is newer than {branch} ")
    t = t[: m.start(1)] + branch + t[m.end(1) :]

    # package prefixes and PHP_INI_DIR
    return re.sub(r"\bphp[0-9]{2}\b", php, t)


def update_readme(t: str, dockerfile: str) -> str:
    # sync version badges with Dockerfile
    m = re.search(r"MANTIS_VER=([0-9.]+)", dockerfile)
    assert m
    t = re.sub(r"(badge/MantisBT-)[0-9.]+(-)", r"\g<1>" + m.group(1) + r"\g<2>", t)

    m = re.search(r"PHP_INI_DIR=/etc/php([0-9])([0-9])", dockerfile)
    assert m
    php = f"{m.group(1)}.{m.group(2)}"
    t = re.sub(r"(badge/PHP-)[0-9.]+(-)", r"\g<1>" + php + r"\g<2>", t)

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
        "--keep-base-version",
        action="store_true",
        default=False,
        help="Do not update Alpine and PHP to the latest versions",
    )

    args = parser.parse_args()

    filepath = "Dockerfile"
    log(f"Patch {filepath}...")
    with open(filepath, "r") as file:
        t = file.read()

    t_old = t

    if args.mantis_version is not None:
        t = update_mantis(t, args.mantis_version)

    if not args.keep_base_version:
        t = update_base(t)

    patch_file(filepath, t, t_old)

    readme_path = "README.md"
    log(f"Patch {readme_path}...")
    with open(readme_path, "r") as file:
        r_old = file.read()
    patch_file(readme_path, update_readme(r_old, t), r_old)

    # image tag version, read by build-image.sh
    version_path = "VERSION"
    log(f"Patch {version_path}...")
    m = re.search(r"MANTIS_VER=([0-9.]+)", t)
    assert m
    with open(version_path, "r") as file:
        v_old = file.read()
    patch_file(version_path, m.group(1) + "\n", v_old)
