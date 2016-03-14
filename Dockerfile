FROM hub.bccvl.org.au/plone/plone:4.3.8

RUN yum install -y git gdal-devel gdal-python gcc-c++ exempi-devel && \
    yum clean all

COPY files/versions.cfg $Z_HOME/
COPY files/base.cfg $Z_HOME/
COPY files/test.cfg $Z_HOME/

WORKDIR $Z_HOME

RUN $Z_HOME/build.sh

COPY files/celeryconfig.py $Z_HOME/celeryconfig.py
COPY files/bccvl.ini $Z_CONF/bccvl.ini

ENV Z_CONFIG_FILE $Z_HOME/parts/instance/etc/zope.conf

ENV TZ AEST-10
#ENV BROKER_URL amqp://bccvl:bccvl@rabbitmq:5672/bccvl
ENV BCCVL_CONFIG ${Z_CONF}/bccvl.ini
ENV CELERY_CONFIG_MODULE celeryconfig

EXPOSE 8080

CMD ./bin/instance console
