import os

BROKER_URL = os.environ.get('BROKER_URL',
                            "amqp://bccvl:bccvl@rabbitmq:5672/bccvl")
if os.environ.get('BROKER_USE_SSL'):
    BROKER_USE_SSL = {
      'ca_certs': os.environ.get('BROKER_USE_SSL_CA_CERTS'),
      'cert_reqs': int(os.environ.get('BROKER_USE_SSL_CERT_REQS', '2')),
      'keyfile': os.environ.get('BROKER_USE_SSL_KEYFILE'),
      'certfile': os.environ.get('BROKER_USE_SSL_CERTFILE'),
    }

BROKER_HEARTBEAT = 10

ADMINS = [email for email in os.environ.get('ADMINS', 'y.liaw@griffith.edu.au').split(' ') if email]

CELERY_IMPORTS = [name for name in os.environ.get('CELERY_IMPORTS', '').split(' ') if name]
