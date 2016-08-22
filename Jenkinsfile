
node {
    // fetch source
    stage 'Checkout'

    checkout scm

    // buildout
    stage 'Buildout'

    def baseimage = docker.image(getDockerFrom())
    def setuptools_version = getBuildoutVersion("files/versions.cfg", "setuptools")

    // FIXME: make sure git is set up on node (HOME should be set to JENKINS_HOME here)
    // we have to make sure git user.name is cnofigured so that git does not try to
    // query /etc/passwd for potentially non existent jekins user  (uid 1000) inside container
    // and make sure, that HOME inside container points to JENKINS_HOME (from before running the container)
    // sh "git config --global user.email 'jenkins@bccvl.org.au'"
    // sh "git config --global user.name 'jenkins'"
    // baseimage.inside("-e HOME='${env.JENKINS_HOME}'") {
    baseimage.inside() {
        sh "python files/bootstrap-buildout.py --setuptools-version=${setuptools_version} -c files/jenkins.cfg"
        sh "./files/bin/buildout -c files/jenkins.cfg"
    }

    stage 'Test'

    baseimage.inside('-v /etc/machine-id:/etc/machine-id') {
        sh "CELERY_CONFIG_MODULE='' xvfb-run -l -a ./files/bin/jenkins-test-coverage"
    }

    // capture unit test outputs in jenkins
    step([$class: 'JUnitResultArchiver', testResults: 'files/parts/jenkins-test/testreports/*.xml'])

    // capture coverage report
    publishHTML(target:[allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'files/parts/jenkins-test/coverage-report', reportFiles: 'index.html', reportName: 'Coverage Report'])

    // capture robot result
    step([$class: 'RobotPublisher',
          outputPath: 'files/parts/jenkins-test',
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
