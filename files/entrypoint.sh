#!/bin/bash

# make sure config files are in place and readable
if [ -e "${BCCVL_ETC}/zope/zope.conf" ] ; then
    ln -sf "${BCCVL_ETC}/zope/zope.conf" "${BCCVL_HOME}/parts/instance/etc/zope.conf"
    chmod 600 "${BCCVL_ETC}/zope/zope.conf"
    chown ${BCCVL_USER}:${BCCVL_USER} "${BCCVL_ETC}/zope/zope.conf"
fi
if [ -e "${BCCVL_ETC}/wsgi/zope.wsgi" ] ; then
    ln -sf "${BCCVL_ETC}/wsgi/zope.wsgi" "${BCCVL_HOME}/zope.wsgi"
    chmod 600 "${BCCVL_ETC}/wsgi/zope.wsgi"
    chown ${BCCVL_USER}:${BCCVL_USER} "${BCCVL_ETC}/wsgi/zope.wsgi"
fi
if [ -e "${BCCVL_ETC}/bccvl/bccvl.ini" ] ; then
    ln -sf "${BCCVL_ETC}/bccvl/bccvl.ini" "${BCCVL_HOME}/bccvl.ini"
    chmod 600 "${BCCVL_ETC}/wsgi/bccvl.ini"
    chown ${BCCVL_USER}:${BCCVL_USER} "${BCCVL_ETC}/wsgi/bccvl.ini"
fi
# change permission of storage location
if [ -e "${BCCVL_VAR}" ] ; then
    # \; makes semicolon for find exec (escaped from shell)
    find "${BCCVL_VAR}" -type d -exec chmod 700 {} \;
    find "${BCCVL_VAR}" -type f -exec chmod 600 {} \;
    chown -R ${BCCVL_USER}:${BCCVL_USER} "${BCCVL_VAR}"
fi

exec "$@"
