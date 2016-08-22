
node {
    // fetch source
    stage 'Checkout'

    checkout scm

    // buildout
    stage 'Buildout'
    def baseimage = docker.image('hub.bccvl.org.au/bccvl/bccvlbase:2016-08-21')

    baseimage.inside() {
        sh "./bin/buildout"
    }

    stage 'Test'

    baseimage.inside('-v /etc/machine-id:/etc/machine-id') {
        sh "CELERY_CONFIG_MODULE='' xvfb-run -l -a ./bin/jenkins-test-coverage"
    }

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
