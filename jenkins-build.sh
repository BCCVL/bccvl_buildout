#!/bin/bash

if [ -z "$WORKSPACE" ]; then
    echo "Guessing WORKSPACE is .."
    WORKSPACE='..'
fi

BIN_DIR="bin"
PYTHON="$BIN_DIR/python"
PIP="$BIN_DIR/pip"
BUILDOUT="$BIN_DIR/buildout"
JENKINS_TEST="$BIN_DIR/jenkins-test-coverage"

echo "Using WORKSPACE $WORKSPACE"
cd "$WORKSPACE"

echo "Setting up virtualenv in $WORKSPACE"
curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-12.0.7.tar.gz
tar -xvzf virtualenv-12.0.7.tar.gz
python virtualenv-12.0.7/virtualenv.py -p /usr/bin/python2.7 .
source bin/activate
easy_install setuptools==0.9.8

echo "Python version:"
"$PYTHON" --version

BRANCH="${GIT_BRANCH#*/}"
echo "Configuring buildout for branch $BRANCH"
cp "buildout.cfg.jenkins.${BRANCH}" buildout.cfg

echo "Run bootstrap and then buildout"
"$PYTHON" bootstrap.py -v 2.2.1
"$BUILDOUT"

CELERY_CONFIG_MODULE='' xvfb-run -a "$JENKINS_TEST"

RESULT=$?

exit $RESULT
