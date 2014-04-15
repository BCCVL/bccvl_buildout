# Module:   fourstore
# Date:     12th November 2013
# Author:   James Mills, j dot mills at griffith dot edu dot au

"""fourstore tasks"""


from __future__ import print_function


from fabric.api import abort, hide, local, settings, task


from .utils import msg, pidof, readoptions, requires, saveoptions


@task()
@requires("4s-backend-info", "4s-backend-setup", "pidof")
def build(**options):
    """Build and install 4store

    Options:
        kb  - Name of Knowledge Base to setup
    """

    options = readoptions(options)
    saveoptions(options)

    kb = options.get("kb", "default")

    if pidof("4s-backend") or pidof("4s-httpd"):
        abort("4store is currently running! Please stop before running build!")

    with settings(hide("warnings"), warn_only=True):
        if local("4s-backend-info {0:s}".format(kb)):
            abort((
                "{0:s} knowledge base already exists! "
                "Please run clean before running build!"
            )).format(kb)

    with msg("Creating knowledge base {0:s}".format(kb)):
        local("4s-backend-setup {0:s}".format(kb))


@task()
@requires("4s-backend-destroy", "pidof")
def clean(**options):
    """Clean up and destroy 4store knowledge base

    Options:
        kb  - Name of Knowledge Base to destroy
    """

    options = readoptions(options)
    saveoptions(options)

    kb = options.get("kb", "default")

    if pidof("4s-backend") or pidof("4s-httpd"):
        abort("4store is currently running! Please stop before running clean!")

    local("4s-backend-destroy {0:s}".format(kb))


@task()
@requires("4s-backend", "4s-httpd", "pidof")
def start(**options):
    """Startup Plone and 4store

    Options:
        kb  - Name of Knowledge Base to destroy
    """

    options = readoptions(options)
    saveoptions(options)

    kb = options.get("kb", "default")
    port = options.get("port", "6801")

    if not pidof("4s-backend"):
        local("4s-backend {0:s}".format(kb))
    else:
        print("4s-backend already running!")

    if not pidof("4s-httpd"):
        local("4s-httpd -p {0:s} {1:s}".format(port, kb))
    else:
        print("4s-httpd already running!")


@task()
@requires("pidof")
def stop():
    """Stop 4store"""

    if pidof("4s-backend"):
        local("pidof -k 4s-backend")

    if pidof("4s-httpd"):
        local("pidof -k 4s-httpd")
