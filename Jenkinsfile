
// Image version numbers:
//    <tag>-<commitcount>-<hash>
//    <tag>-<jenkins build>-<hash>

// Build Strategy
//   feature branches ... just build and test
//   develop ... build image from source clones (force rebuild?)
//   qa/master ... build from packaged versions only (no force required as buildout clone should be changed in any case)

def imagename = null;

node {
    catchError { // catch all exceptions to do some cleanup at the end (e.g. send email)
        // fetch source
        stage 'Checkout'

        checkout scm

        // buildout
        stage 'Build'

        def image = null;

        if (['feature/develop_docker', 'master', 'qa'].contains(env.BRANCH_NAME)) {
            // some branch we want to build an image from
            // build into image

            def tag = null;
            def build_args = null;
            if (env.BRANCH_NAME == 'feature/develop_docker') {
                tag = 'latest';
                build_args = "--build-arg BUILDOUT_CFG=develop.cfg ."
            } else {
                // it is important here, that all package versions are pinned, so that build out repo get's at least a new 'revision-number' after last tag
                tag = getGitTag();
            }

            imagename = newImageTag('bccvl/bccvl', tag)

            image = docker.build(imagename, build_args);

        } else {
            // some test only branch
            // build into jenkins workspace as usual
            image = docker.image(getDockerFrom())
            def setuptools_version = getBuildoutVersion("files/versions.cfg", "setuptools")

            // FIXME: make sure git is set up on node (HOME should be set to JENKINS_HOME here)
            // we have to make sure git user.name is cnofigured so that git does not try to
            // query /etc/passwd for potentially non existent jekins user  (uid 1000) inside container
            // and make sure, that HOME inside container points to JENKINS_HOME (from before running the container)
            def tmp_home = pwd tmp:true
            image.inside("-e HOME='${tmp_home}'") {
                // setup git, so that mr.developer doesn't have lookup non existent uid  1000
                // TODO: maybe use given git credentials instead of generic jenkins values?
                sh "git config --global user.email 'jenkins@bccvl.org.au'"
                sh "git config --global user.name 'jenkins'"
                sh "cd files; python bootstrap-buildout.py --setuptools-version=${setuptools_version} -c jenkins.cfg"
                sh "cd files; ./bin/buildout -c jenkins.cfg"
            }
        }

        stage 'Test'

        if (['feature/develop_docker', 'master', 'qa'].contains(env.BRANCH_NAME)) {
            // run tests inside freshly built image

            def container = image.run('-t -v /etc/machine-id:/etc/machine-id', 'cat')

            try {
                // TODO: maybe do exec echo ${BCCVL_USER} and exec pwd to get user name and workdir?

                // FIXME: is the chown really necessary? should we change the build process here?
                sh 'docker exec ${container.id} chown -R bccvl:bccvl parts'

                sh "docker exec -u bccvl:bccvl ${container.id} bash -c 'CELERY_CONFIG_MODULE= xvfb-run -l -a ./bin/jenkins-test-coverage'"

                sh "docker cp ${container.id}:/opt/bccvl/parts/jenkins-test jenkins-test"

                publish_test_results('.')

            } finally {
                container.stop()
            }

        } else {
            // run tests from workspace build
            // FIXME: see FIXME above
            //        here it is firefox that needs a writable HOME folder
            def tmp_home = pwd tmp:true
            image.inside("-v /etc/machine-id:/etc/machine-id -e HOME='${tmp_home}'") {
                sh "cd files; CELERY_CONFIG_MODULE='' xvfb-run -l -a ./bin/jenkins-test-coverage"
            }

            publish_test_results('files/parts')

        }

        if (['feature/develop_docker', 'qa', 'master'].contains(env.BRANCH_NAME)) {
            // we want to push and deploy our image from these branches

            stage 'Push Image'

            if (currentBuild.result == 'SUCCESS') {

                image.push();
                slackSend color: 'good', message: "New Image ${imagename}:${imagetag}\n${env.JOB_URL}"

            } else {
                // we should abort the pipeline in any case
                error "Build status is ${currentBuild.result}. Not continuing with push and deploy"

            }
        }

    }

    // use jenkins mailer to send out build notifications
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'g.weis@griffith.edu.au',
          sendToIndividuals: true])


}


// In case we are on a deployment branch and build was a success,
// We have to kick off deployment as well.
// Have to do start this outside of a node, as we may have an approval step
if (currentBuild.result == 'SUCCESS') {

    switch (env.BRANCH_NAME) {
        case 'master':

            stage 'Approve'

            mail(to: 'g.weis@griffith.edu.au',
                 subject: "Job '${env.JOB_NAME}' (${env.BUILD_NUMBER}) is waiting for input",
                 body: "Please go to ${env.BUILD_URL}.");

            slackSend color: 'good', message: "Ready to deploy ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"

            input 'Ready to deploy?';

        case 'qa':
        case 'feature/develop_docker':

            stage 'Deploy'

            node {

                deploy('BCCVL', env.BRANCH_NAME, imagename)

                slackSend color: 'good', message: "Deployed ${env.JOB_NAME} ${env.BUILD_NUMBER}"

            }

    }

}



def publish_test_results(prefix='') {
    // capture unit test outputs in jenkins
    step([$class: 'JUnitResultArchiver', testResults: "${prefix}/jenkins-test/testreports/*.xml"])

    // capture coverage report
    //publishHTML(target:[allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: "${prefix}/jenkins-test/coverage-report", reportFiles: 'index.html', reportName: 'Coverage Report'])

    // capture robot result
    step([$class: 'RobotPublisher',
          outputPath: "${prefix}/jenkins-test",
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
