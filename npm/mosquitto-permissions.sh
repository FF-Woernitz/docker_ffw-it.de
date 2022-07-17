#!/bin/bash

chgrp 1883 /etc/letsencrypt/archive
chgrp 1883 /etc/letsencrypt/archive/npm-1
chmod g+rx /etc/letsencrypt/archive
chmod g+rx /etc/letsencrypt/archive/npm-1
chmod -R g+r /etc/letsencrypt/archive/npm-1