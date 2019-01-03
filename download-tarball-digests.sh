#!/bin/sh
MANTIS_VER=$1
curl  --max-redirs 2 -L http://downloads.sourceforge.net/project/mantisbt/mantis-stable/${MANTIS_VER}/mantisbt-${MANTIS_VER}.tar.gz.digests

