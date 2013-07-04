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
    

