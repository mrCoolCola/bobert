#!/usr/bin/env bash
mkdir tarball
mkdir tarball/etc/systemd/system -p
mkdir tarball/usr/bin -p
cp target/debug/bobert tarball/usr/bin
touch tarball/etc/systemd/system/bobert.service
