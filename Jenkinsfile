node('docker') {

    try {

        stage('Checkout') {
            // clean git clone, but don't fail in case it doesn't exist yet
            sh(script: 'git clean -x -d -f -f -e "eggs"', returnStdout: true)
            checkout scm
        }

        // start up build container
        def img = docker.image('hub.bccvl.org.au/bccvl/bccvlbase:2017-02-23')
        img.inside('-v /etc/machine-id:/etc/machine-id') {

            withVirtualenv() {

                stage('Build') {
                    sh '. ${VIRTUALENV}/bin/activate; pip install -r files/requirements-build.txt'
                    // setup git for buildout
                    sh 'git config --global user.name Jenkins'
                    sh 'git config --global user.email jenkins@bccvl.nectar.org.au'
                    // run build
                    sh '. ${VIRTUALENV}/bin/activate; cd files; buildout'
                }

                stage('Test') {
                    sh '. ${VIRTUALENV}/bin/activate; cd files; CELERY_CONFIG_MODULE= ; xvfb-run -l -a ./bin/jenkins-test-coverage'

                    // capture test result
                    step([
                        $class: 'XUnitBuilder',
                        thresholds: [
                            [$class: 'FailedThreshold', failureThreshold: '0',
                                                        unstableThreshold: '1']
                        ],
                        tools: [
                            [$class: 'JUnitType', deleteOutputFiles: true,
                                                  failIfNotNew: true,
                                                  pattern: "files/parts/jenkins-test/testreports/*.xml",
                                                  stopProcessingIfError: true]
                        ]
                    ])
                    // capture robot result
                    step([
                        $class: 'RobotPublisher',
                        outputPath: "files/parts/jenkins-test",
                        outputFileName: 'robot_output.xml',
                        disableArchiveOutput: false,
                        reportFileName: 'robot_report.html',
                        logFileName: 'robot_log.html',
                        passThreshold: 90,
                        unstableThreshold: 100,
                        onlyCritical: false,
                        otherFiles: '',
                        enableCache: false
                    ])

                }
            }
        }

    } catch (err) {
        throw err
    } finally {

        // clean git clone (removes all build files like virtualenv etc..)
        sh 'git clean -x -d -f -e "eggs"'

        step([
            $class: 'Mailer',
            notifyEveryUnstableBuild: true,
            recipients: 'gerhard.weis@gmail.com ' + emailextrecipients([
                [$class: 'CulpritsRecipientProvider'],
                [$class: 'RequesterRecipientProvider']
            ])
        ])

    }

}