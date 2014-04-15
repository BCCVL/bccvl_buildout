# Package:  fabfile
# Date:     18th June 2013
# Author:   James Mills, j dot mills at griffith dot edu dot au

"""TerraNova Fabric"""


from __future__ import print_function

from os import path
from functools import partial


from fabric.api import execute, local, prompt, task


import fourstore
import help  # noqa
from .utils import pgrep, requires, readoptions, saveoptions, tobool


IPV4_BIND_REGEX = r"^(2[0-4][0-9]|[01]?[0-9]?[0-9]|25[0-5])\D{1,5}(2[0-4][0-9]|[01]?[0-9]?[0-9]|25[0-5])\D{1,5}(2[0-4][0-9]|[01]?[0-9]?[0-9]|25[0-5])\D{1,5}(2[0-4][0-9]|[01]?[0-9]?[0-9]|25[0-5])(?:[:]([0-9]+))?$"  # noqa

BUILDOUTCFG_TEMPLATE = path.join(
    path.dirname(__file__),
    "files",
    "buildout.cfg.tmpl"
)


@task()
def configure():
    """Configure a buildout.cfg configuration file"""

    # Tuple of (key, question, default, validate, function)
    vars = (
        (
            "newest",
            "Always build and install newest packages?",
            "n",
            r"^[yn]$(?i)", lambda x: (tobool(x) and "true") or "false"
        ),
        (
            "mirror",
            "Enter the URL of a local PyPi miorror you'd like to use:",
            "",
            r"^(http[s]?\:\/\/.*)?$",
            partial(lambda x: (x and "index = {0:s}".format(x)) or "")
        ),
        (
            "adminuser",
            "Enter Administrator Username:",
            "admin",
            None,
            None
        ),
        (
            "adminpass",
            "Enter Administrator Password:",
            "admin",
            None,
            None
        ),
        (
            "bind",
            "Specify interface to bind to (a.b.c.d:[port]):",
            "0.0.0.0",
            IPV4_BIND_REGEX,
            None
        ),
    )

    options = {}

    for key, question, default, validate, function in vars:
        result = prompt(question, default=default, validate=validate)
        if callable(function):
            result = function(result)
        options[key] = result

    with open("buildout.cfg", "w") as f:
        f.write(open(BUILDOUTCFG_TEMPLATE, "r").read() % options)


@task()
@requires("python")
def build(**options):
    """Build and install required dependencies

    Options:
        config  - An optional path to pre-configured buildout configuration.

    This task also runs the fourstore.build task and can also take
    optional options from the fourstore.build task. See: fab
    """

    options = readoptions(options)
    config = options.get("config", None)
    saveoptions(options)

    if config is not None:
        local("cp {0:s} buildout.cfg".format(config))
    else:
        if not path.exists("buildout.cfg"):
            print("No buildout.cfg configuration found!")
            execute(configure)

    execute(fourstore.build, **options)
    execute(fourstore.start, **options)

    try:
        if not path.exists("./bin/buildout"):
            local("python bootstrap-buildout.py")

        local("./bin/buildout")
    finally:
        execute(fourstore.stop)


@task()
def clean(**options):
    """Clean up build files and directories

    Options:
        src     - Whether to delete the src directory (Default: no)
        force   - Whehter ro ignore the warning and prompt (Default: no)
    """

    src = tobool(options.get("src", "no"))
    force = tobool(options.get("force", "no"))

    proceed = False

    if not force:
        print(
            "WARNING: This task will NUKE everything that buildout produced!"
        )
        proceed = prompt(
            "Is this ok?",
            default="n",
            validate=r"^[YyNn]?$"
        ) in "yY"

    if proceed or force:
        files = [".installed.cfg", ".mr.developer.cfg", "picked-versions.cfg"]
        local("rm -rf {0:s}".format(" ".join(files)))

        dirs = ["bin", "etc", "var", "eggs", "parts", "develop-eggs"]
        if src:
            dirs.append("src/*")

        for dir in dirs:
            local("rm -rf {0:s}".format(dir))

        execute(fourstore.clean, **options)


@task()
def start(**options):
    """Start Plone and 4store

    Options:
        fg    - An optional parameter controlling whetehr to run
                in foreground or background (Default: True)

    This task also runs the fourstore.build task and can also take
    optional options from the fourstore.build task. See: fab
    """

    fg = tobool(options.get("fg", "yes"))

    execute(fourstore.start, **options)

    if not pgrep("zeoserver"):
        local("./bin/zeoserver start")

    try:
        local("./bin/instance-debug {0:s}".format("fg" if fg else "start"))
    finally:
        if fg:
            execute(fourstore.stop)
            local("./bin/zeoserver stop")


@task()
@requires("pkill")
def stop(**options):
    """Stop Plone and 4store

    Options: None
    """

    execute(fourstore.stop)

    if pgrep("zeoserver"):
        local("./bin/zeoserver stop")

    if pgrep("instance-debug"):
        local("pkill -f instance-debug")


@task()
@requires("./bin/zeoserver", "./bin/instance-debug", "pidof")
def run(*args, **options):
    """Run a script through a Plone instance

    Options: None

    This task also runs the fourstore.build task and can also take
    optional options from the fourstore.build task. See: fab help:fourstore

    Example:

        fab run:/path/to/script,-arg1,-arg2

    Arguments are separated by commas. The first argument is the path
    to the script to run under the Plone instnace, following arguments
    are passed as arguments to the script.
    """

    execute(fourstore.start, **options)

    if not pgrep("zeoserver"):
        local("./bin/zeoserver start")

    try:
        local("./bin/instance-debug run {0:s}".format(" ".join(args)))
    finally:
        execute(fourstore.stop)
        local("./bin/zeoserver stop")


@task()
def test():
    """Run the test suite"""

    local("./bin/test")
