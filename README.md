bccvl_buildout
==============

This repository is intended to be used to build Docker a container, but should be able to buildout normally as well.

AS a first step clone this repo to your system and cd into that directory.

    git clone https://github.com/BCCVL/bccvl_buildout.git
    cd bccvl_buildout


Using Docker
============

Building a Container
--------------------

Whatever docker setup you use it should be as simple as running

    docker build -t bccvl .

Assigning a tag during build makes it easier to refer to the final image later on.

Running tests
-------------

Running all the tests inside the container requires a few more packages to be installed.

    docker run --rm -it bccvl bash
    yum install -y xorg-x11-server-Xvfb firefox which
    dbus-uuidgen > /etc/machine-id
    CELERY_CONFIG_MODULE='' xvfb-run -l -a ./bin/test

Using the Container
-------------------

BCCVL requires a couple of additional services to enable all features, but to just get the service up you can run the container as is. This will start a Zope server with an embedded ZODB database which stores all data in a volume.

    docker run -P bccvl

The server should be accessible at http://<ip>:8080


Deployment Options
------------------

There are various environment variables that can be set to configure the container.

    TZ
        set time zone for server

    BROKER_URL
        the url celery uses to connect to a message queue

    BROKER_USE_SSL
        if set, celery uses SSL to connect to the message queue, and uses the other SSL options to verify the connection

    BROKER_USE_SSL_CA_CERTS
        The CA certificate chain to verify server certs

    BROKER_USE_SSL_CERT_REQS
        Whether to verify server certs at all

    BROKER_USE_SSL_KEYFILE
        The SSL client private key

    BROKER_USE_SSL_CERTFILE
        The SSL client public certificate

    ADMINS
        A space seperated list of email addresses

    CELERY_IMPORTS
        A space separated list of module names, celery will load at startup and search for tasks


Running Zope in debug mode
--------------------------

    docker run --rm -it -p 8080:8080 bccvl ./bin/instance fg

Running Zope via uwsgi
----------------------

While the following command works, it should be used together with a custom zope.conf file.

    docker run --rm -it -p 8080:8000 bccvl ./bin/uwsgiapp -x parts/uwsgiapp/uwsgi.xml --ini-paste zope.wsgi --processes 1 --enable-threads --uid bccvl --gid bccvl --http :8000

Override configuration files
----------------------------

The container reads 3 configuration files to configure various systems.


    1. /etc/opt/bccvl/bccvl/bccvl.ini

        setup cookie settings and logging (for celery process)

    2. /etc/opt/bccvl/wsgi/zope.wsgi

        a paste ini file to be used with uwsgi

    3. /etc/opt/bccvl/zope/zope.conf

        zope configuration file. This is the place to configure database backends (ZEO, RelStorage), Zope logging and server ports.
        If using uwsgi, ZServer should be completely disabled here.

Create initial site
-------------------

The initial site can be created via the web interface or by calling the site setup script. See --help for options.

    docker exec ./bin/instance manage --help

    no parameters ... setup site with defaults

    --upgrade ... create new site or if site exists run available upgrade steps

    --lastupgrade ... force re-run latest upgrade step


Import data
-----------

Daasets can be imported in a similar way. For development the following steps are recommended.

    docker exec ./bin/instance testsetup --siteurl http://<ip>:8080 --dev
    docker exec ./bin/instance testsetup --siteurl http://<ip>:8080 --test


Using buildout directly
=======================

Alternatively you can just use buildout. The recommended way is to setup a virtualenv at the project root and run buildout from within the files folder.

    virtualenv --python python2.7 .
    . bin/activate
    cd files
    python bootstrap-buildout.py
    ./bin/buildout

Depending on your operating system you may need to install development packages of various system packages, and potentially set LD_FLAGS and CFLAGS environment variables to build Python packages with C extensions.
