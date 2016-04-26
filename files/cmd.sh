#!/bin/bash

if [ -e "/etc/opt/zope/etc/zope.conf" ] ; then
    cp /etc/opt/zope/etc/zope.conf /opt/zope/parts/instance/etc/zope.conf
fi



exec ./bin/instance console
