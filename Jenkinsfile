
def imagename;
def imagetag;

node {
    // fetch source
    stage 'Checkout'

    checkout scm

    // build image
    stage 'Build Image'

    imagename = 'hub.bccvl.org.au/bccvl/bccvl'
    def img = docker.build(imagename)

    // test image
    stage 'Test'

    docker.image(imagename).inside("-u root") {

        // run tests
        sh "yum install -y xorg-x11-server-Xvfb firefox which"
        try {
            // ensure we have a dbus machine-id for firefox
            sh "dbus-uuidgen > /etc/machine-id"
            // run tests
            sh "cd \"${BCCVL_HOME}\"; CELERY_CONFIG_MODULE='' xvfb-run -l -a ./bin/jenkins-test-coverage"
        } catch(err) {
            echo "Caugh Exception marking build as 'FAILURE'"
            currentBuild.result = 'FAILURE'
        }


        // copy test results to workdir
        sh "cd \"${BCCVL_HOME}\"; ./bin/coverage html -d parts/jenkins-test/coverage-report"
        sh 'cp -rf \"${BCCVL_HOME}/parts/jenkins-test\" "${PWD}/"'

        // capture unit test outputs in jenkins
        step([$class: 'JUnitResultArchiver', testResults: 'jenkins-test/testreports/*.xml'])

        // capture coverage report
        publishHTML(target:[allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'jenkins-test/coverage-report', reportFiles: 'index.html', reportName: 'Coverage Report'])

        // capture robot result
        step([$class: 'RobotPublisher',
                        outputPath: 'jenkins-test',
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

    imagetag = getBuildoutVersion("files/versions.cfg", "org.bccvl.site")

    // publish image to registry
    switch(env.BRANCH_NAME) {
        case 'feature/develop_docker':
        case 'master':
        case 'qa':
            stage 'Image Push'

            img.push(imagetag)
            //img.push('latest')

            slackSend color: 'good', message: "New Image ${imagename}:${imagetag}\n${env.JOB_URL}"

            break
    }

}

switch(env.BRANCH_NAME) {

    case 'master':

        stage 'Approve'

        mail(to: 'g.weis@griffith.edu.au',
             subject: "Job '${env.JOB_NAME}' (${env.BUILD_NUMBER}) is waiting for input",
             body: "Please go to ${env.BUILD_URL}.");

        slackSend color: 'good', message: "Ready to deploy ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"

        input 'Ready to deploy?';

    case 'feature/develop_docker':
    case 'qa':

        stage 'Deploy'

        node {

            deploy("BCCVL", env.BRANCH_NAME, "${imagename}:${imagetag}")

            slackSend color: 'good', message: "Deployed ${env.JOB_NAME} ${env.BUILD_NUMBER}"

        }

        break

}
