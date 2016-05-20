#!/bin/bash

# assume we run inside xvfb-run and force later commands to use tcp to connect to xvfb
export DISPLAY=localhost:$DISPLAY

# run coverage test suite
CELERY_CONFIG_MODULE='' ./bin/jenkins-test-coverage
