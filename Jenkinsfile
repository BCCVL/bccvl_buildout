pipeline {

    agent {
        docker {
            image 'hub.bccvl.org.au/bccvl/bccvlbase:2017-02-20'
        }
    }

    stages {

        stage('Build') {

            steps {

                // clean environment (keep eggs)
                sh 'git clean -x -d -f -e "eggs"'

                withPyPi() {
                    // we should be inside the container with the workspace mounted at current working dir
                    // and running as jenkins user (should have read/write access to workspace)
                    // we need a virtual env here
                    sh 'virtualenv -p python2.7 --system-site-packages ./virtualenv'
                    sh 'virtualenv --relocatable ./virtualenv'
                    // convert virtualenv to relocatable to avoid problems with too long shebangs
                    sh '. ./virtualenv/bin/activate; pip install -r files/requirements-build.txt'
                    sh 'virtualenv --relocatable ./virtualenv'
                    sh '. ./virtualenv/bin/activate; cd files; buildout'
                }

            }

        }

        stage('Test') {

            steps {
                sh '. ./virtualenv/bin/activate; cd files; CELERY_CONFIG_MODULE= ; xvfb-run -l -a ./bin/jenkins-test-coverage'

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
                                              pattern: "virtualenv/files/parts/jenkins-test/testreports/*.xml",
                                              stopProcessingIfError: true]
                    ]
                ])
                // capture robot result
                step([$class: 'RobotPublisher',
                      outputPath: "virtualenv/files/parts/jenkins-test",
                      outputFileName: 'robot_output.xml',
                      disableArchiveOutput: false,
                      reportFileName: 'robot_report.html',
                      logFileName: 'robot_log.html',
                      passThreshold: 90,
                      unstableThreshold: 100,
                      onlyCritical: false,
                      otherFiles: '',
                      enableCache: false])


            }

        }

    }

    post {

        always {
            echo "This runs always"

            // clean git clone (removes all build files like virtualenv etc..)
            sh 'git clean -x -d -f -e "eggs"'

            // does this plugin get committer emails by themselves?
            // alternative would be to put get commiter email ourselves, and list of people who need to be notified
            // and put mail(...) step into each appropriate section
            // => would this then send 2 emails? e.g. changed + state email?
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

}
