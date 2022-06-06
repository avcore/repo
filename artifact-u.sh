#!/bin/bash

ls -ltr foo_* | tail -n 1 | awk '{print $9}' | xargs  dpkg -i
