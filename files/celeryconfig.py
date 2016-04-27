import os

BROKER_URL = os.environ.get('BROKER_URL',
                            "amqp://bccvl:bccvl@rabbitmq:5672/bccvl")
if os.environ.get('BROKER_USE_SSL'):
    BROKER_USE_SSL = {
      'ca_certs': os.environ.get('BROKER_USE_SSL_CA_CERTS'),
      'cert_reqs': int(os.environ.get('BROKER_USE_SSL_CERT_REQS', '2'))
    }
    if os.environ.get('BROKER_USE_SSL_KEFILE'):
        BROKER_USE_SSL["keyfile"] = os.environ.get('BROKER_USE_SSL_KEYFILE')
    if os.environ.get('BROKER_USE_SSL_CERTFILE'):
        BROKER_USE_SSL["certfile"] = os.environ.get('BROKER_USE_SSL_CERTFILE')

ADMINS = [email for email in os.environ.get('ADMINS', 'g.weis@griffith.edu.au').split(' ') if email]

CELERY_IMPORTS = [name for name in os.environ.get('CELERY_IMPROTS', '').split(' ') if name]
