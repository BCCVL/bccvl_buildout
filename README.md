bccvl_buildout
==============

Setting up plone on your local development box
----------------------------------------------

Clone this repo to your system and cd into that directory.

    git clone https://github.com/BCCVL/bccvl_buildout.git
    cd bccvl_buildout

Create a `buildout.cfg` by copying the example file:

    cp buildout.cfg.development buildout.cfg

Edit your new `buildout.cfg` file and add this section.  It resets the usernames plone will use back to their default, which is your local user:

    [users]
    main =
    cache =
    transform =
    balancer =
    zope =
    supervisor =

If you aren't at Griffith Uni, you should also comment out the index line that points at Griffith's install mirror:

    # index = http://mirror.rcs.griffith.edu.au:3143/root/pypi/+simple

Finally, run boostrap then buildout:

    $ python bootstrap.py
    $ ./bin/buildout

Alternatively you can perform the following steps:

    $ ./bootstrap.sh
    $ fab build

This will prompt you and assist in the creation of a "development"
``buildout.cfg``. See: ``fab -l`` for a list of develpoment commands
and ``fab help:<command>`` for specific help on a development task.


Running tests:
--------------

Buildout also generates a script to run all configured tests:

    $ ./bin/test

The test runner accepts a couple of different options. Most useful are
probably --layer=LAYERNAME and -t TESTNAME. LAYERNAME and TESTNAME are
interpreted as regular expressions and can be used to run only specifc
tests instead of the whole test suite.

Use --list-tests to see all test layers and test names.

To generate test result output in an xml format that can be read by
Jenkins use:

    $ ./bin/jenkins-test

The Jenkins test runner is essentially the same as the normal test
runner, and accepts the same command line parameters.
