
node {
    // fetch source
    stage 'Checkout'

    checkout scm

    // buildout
    stage 'Buildout'
    def baseimage = docker.image(getDockerFrom())

    def setuptools_version = getBuildoutVersion("files/versions.cfg", "setuptools")

    baseimage.inside() {
        sh "cd files; python bootstrap-buildout.py --setuptools-version=${setuptools_version}"
        sh "cd files; ./bin/buildout"
    }

    stage 'Test'

    baseimage.inside('-v /etc/machine-id:/etc/machine-id') {
        sh "cd files; CELERY_CONFIG_MODULE='' xvfb-run -l -a ./bin/jenkins-test-coverage"
    }

    // capture unit test outputs in jenkins
    step([$class: 'JUnitResultArchiver', testResults: 'files/jenkins-test/testreports/*.xml'])

    // capture coverage report
    publishHTML(target:[allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'files/jenkins-test/coverage-report', reportFiles: 'index.html', reportName: 'Coverage Report'])

    // capture robot result
    step([$class: 'RobotPublisher',
          outputPath: 'files/jenkins-test',
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
