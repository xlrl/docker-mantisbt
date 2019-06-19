#!/usr/bin/python3
import requests
import re
import sys


def log(msg):
    print(msg, flush=True, end="")


def logline(msg):
    print(msg, flush=True)

assert len(sys.argv) == 2

m = re.match(r"^[0-9.]+$", sys.argv[1])
assert m
version = m.group(0)

log("Get SHA1 digest for %s..." % version)
url_fmt = "http://downloads.sourceforge.net/project/mantisbt/mantis-stable/{MANTIS_VER}/mantisbt-{MANTIS_VER}.tar.gz.digests"
url = url_fmt.format(MANTIS_VER=version)

resp = requests.get(url)
assert resp.status_code == 200, "Invalid status code %d" % resp.status_code
m = re.search(r"[0-9a-f]{40}", resp.text)
assert m, resp.text
sha1 = m.group(0)
logline(sha1)

filepath = "Dockerfile"
log("Patch %s..." % filepath)
with open(filepath, "r") as file:
    t = file.read()

t_old = t
m = re.search(r"MANTIS_VER ([0-9.]+)", t)
assert m
t_new = t[ : m.start(1)] + version
t = t[m.end(0) : ]

m = re.search(r"MANTIS_SHA1 ([0-9a-f]+)", t)
assert m
t_new += t[ : m.start(1)] + sha1
t_new += t[m.end(0) : ]

if t_new == t_old:
    logline("Unchanged")
else:
    with open(filepath, "w") as file:
        file.write(t_new)
    logline("Updated")
