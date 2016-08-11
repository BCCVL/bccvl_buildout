#!/bin/bash
#
# Use python version. Default: 2.7
#
if [ -z "$PYTHON" ]; then
  PYTHON="/usr/bin/env python"
fi
echo "Using Python: "
echo `$PYTHON --version`
#
# Run bootstrap.py
#
# we need eggs folder so that we can use collective.recipe.environment during bootstrap
mkdir -p eggs
echo "Running $PYTHON bootstrap-buildout.py --setuptools-version=20.1.1"
$PYTHON "bootstrap-buildout.py" --setuptools-version=20.1.1 || exit $?

mkdir -p $BCCVL_VAR
mkdir -p $BCCVL_ETC

#
# Run buildout
#
echo "Running bin/buildout"
./bin/buildout || exit $?

# compile all .po files inside buildout folder
for po in $(find . -path '*/LC_MESSAGES/*.po'); do
    msgfmt -o ${po/%po/mo} $po;
done

chown -R ${BCCVL_USER}:${BCCVL_USER} $BCCVL_ETC
chown -R ${BCCVL_USER}:${BCCVL_USER} $BCCVL_VAR
# make sure all python package files are readable by BCCVL_USER
find eggs -type f -exec chmod 644 {} +
find eggs -type d -exec chmod 755 {} +
