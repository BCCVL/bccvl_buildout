node ('docker') {


    def basename = 'hub.bccvl.org.au/bccvl/bccvl'
    def imgversion = env.BUILD_NUMBER
    def img = null
    def version = null

    def pip_index_url = "http://${env.PIP_INDEX_HOST}:3141/bccvl/dev/+simple/"
    def pip_pre = "True"
    if (env.BRANCH_NAME == 'master') {
        pip_index_url = "http://${env.PIP_INDEX_HOST}:3141/bccvl/prod/+simple/"
        pip_pre = "False"
    }


    try {

        stage('Checkout') {
            checkout scm
            sh 'git clean -x -d -f -f -e "eggs"'
        }

        stage('Build') {

            img = docker.build("${basename}:${imgversion}",
                               "--rm --pull --build-arg PIP_INDEX_URL=${pip_index_url} --build-arg PIP_TRUSTED_HOST=${env.PIP_INDEX_HOST} --build-arg PIP_PRE=${pip_pre} .")

            def gittag = getGitTag()
            if (gittag) {
                imgversion = gittag
            } else {
                imgversion = 'latest'
            }
            img = reTagImage(img, basename, imgversion)
        }

        stage('Test') {
            // image inside runs within jenkins workspace
            img.inside('-u bccvl:bccvl') {
                echo "${BCCVL_HOME}"
                sh 'env'
                sh 'dbus-uuidgen > /etc/machine-id'
                sh 'cd ${BCCVL_HOME}; CELERY_CONFIG_MODULE= ; xvfb-run -l -a ./bin/jenkins-test-coverage '

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
                                              pattern: 'parts/jenkins-test/testreport/*.xml',
                                              stopProcessingIfError: true]
                    ]
                ])

                // capture robot result
                step([$class: 'RobotPublisher',
                      outputPath: "parts/jenkins-test",
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

            img.withRun() { bccvl ->

                def address = sh(script: "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${visualiser.id}",
                                 returnStdout: true).trim()

                img.inside("--add-host=bccvl:${address}") {
                    sh 'curl --fail --silent --show-error --retry 5 --retry-delay 1 http://bccvl:8000/ > /dev/null'
                }
            }
        }

        stage('Publish') {
            if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
                img.push()

                slackSend color: 'good', message: "New Image ${img.id}\n${env.JOB_URL}"
            }
        }

    }
    catch (err) {
        throw error
    }
    finally {
        stage('Cleanup') {
            sh "docker rmi ${img.id}"
        }
    }

}
