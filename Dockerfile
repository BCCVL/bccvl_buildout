FROM hub.bccvl.org.au/centos/centos7-epel:2016-04-15

RUN yum install -y http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm \
    && yum install -y \
    exempi-devel \
    freetype-devel \
    gcc \
    gcc-c++ \
    gettext \
    gdal-devel \
    gdal-python \
    lcms2-devel \
    libffi-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    libtiff-devel \
    libwebp-devel \
    libxml2-devel \
    libxslt-devel \
    libzip-devel \
    mailcap \
    openjpeg-devel \
    openssl-devel \
    postgresql95-devel \
    python-devel \
    && yum clean all

# Setup environment variables
ENV BCCVL_USER bccvl
ENV BCCVL_HOME /opt/${BCCVL_USER}
ENV BCCVL_VAR /var/opt/${BCCCVL_USER}
ENV BCCVL_ETC /etc/opt/${BCCVL_USER}

ENV PATH /usr/pgsql-9.5/bin:$PATH
ENV TZ AEST-10

# add bccvl user to image
RUN groupadd -g 414 ${BCCVL_USER} && \
    useradd -u 414 -g 414 -d ${BCCVL_HOME} -m -s /bin/bash ${BCCVL_USER}

COPY files/* ${BCCVL_HOME}/

WORKDIR ${BCCVL_HOME}

RUN ${BCCVL_HOME}/build.sh

ENV Z_CONFIG_FILE $BCCVL_HOME/parts/instance/etc/zope.conf
ENV BCCVL_CONFIG ${BCCVL_HOME}/bccvl.ini
ENV CELERY_CONFIG_MODULE celeryconfig

EXPOSE 8080

VOLUME ${BCCVL_HOME}/var

# entrypoint and cmd are relative to WORKDIR
ENTRYPOINT ["./entrypoint.sh"]
CMD ["./cmd.sh"]


#TODO:
# install geckodriver for jenkins testing?
# change permission on ssl certs? (or is uwsgi reading them as root?)
#          at lesat make sure they are 700
# set umask for zope/zeo so that it doesn't create files world readable? (maybe there is a zeo/zodb option?)
# should I define volume here? or leave it to deployment?
#buildout:
#    - index = http://mirror.rcs.griffith.edu.au:3143/root/pypi/+simple/
#envvars:
#    - BORKER_URL = amqp://bccvl:bccvl@${hosts:queue}/bccvl
#test-run:
#    - xvfb: CELERY_CONFIG_MODULE='' ./bin/jenkins-test-coverage

#allow bulid of picked-version.cfg:
#    - add newest=True and allow-pickedversion to buildout parameters ... print versions
# in buildout.cfg .... Products.PrintingMailHost is a dev package
# allow override / extension of buildout.cfg in dev env (to add dev packages)

#dev tools:
#    - uwsgi.ini ... egg:paste#evalerror (not useable in multiprocessing env)
