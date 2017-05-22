FROM hub.bccvl.org.au/bccvl/bccvlbase:2017-05-22


# configure pypi index to use
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST
# If set, pip will look for pre releases
ARG PIP_PRE


# Setup environment variables
ENV BCCVL_USER bccvl
ENV BCCVL_HOME /opt/${BCCVL_USER}
ENV BCCVL_VAR /var/opt/${BCCVL_USER}
ENV BCCVL_ETC /etc/opt/${BCCVL_USER}

ENV TZ AEST-10

# add bccvl user to image
RUN groupadd -g 414 ${BCCVL_USER} && \
    useradd -u 414 -g 414 -d ${BCCVL_HOME} -m -s /bin/bash ${BCCVL_USER}

COPY files/ ${BCCVL_HOME}/

WORKDIR ${BCCVL_HOME}

RUN mkdir -p $BCCVL_VAR && \
    mkdir -p $BCCVL_ETC && \
    pip install -r requirements-build.txt && \
    mkdir ~/.buildout && \
    echo -e "[buildout]\nindex = ${PIP_INDEX_URL}" > ~/.buildout/default.cfg && \
    buildout && \
# compile all po files
    for po in $(find . -path '*/LC_MESSAGES/*.po'); do msgfmt -o ${po/%po/mo} $po; done && \
    chown -R ${BCCVL_USER}:${BCCVL_USER} $BCCVL_ETC && \
    chown -R ${BCCVL_USER}:${BCCVL_USER} $BCCVL_VAR && \
# make sure all files and folders are accessible by bccvl user
    find eggs -type f -exec chmod 644 {} + && \
    find eggs -type d -exec chmod 755 {} + && \
    rm -fr ~/.buildout

ENV Z_CONFIG_FILE $BCCVL_HOME/parts/instance/etc/zope.conf
ENV BCCVL_CONFIG ${BCCVL_HOME}/bccvl.ini
ENV CELERY_CONFIG_MODULE celeryconfig

EXPOSE 8080

VOLUME ${BCCVL_VAR}

COPY entrypoint.sh cmd.sh /

# entrypoint and cmd are relative to WORKDIR
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/cmd.sh"]


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
