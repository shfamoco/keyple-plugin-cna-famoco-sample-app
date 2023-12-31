#!/usr/bin/env groovy

currentBuild.result = 'SUCCESS'

def bash(cmd) {
    echo("Running '${cmd}'")
    shellopt = 'set +x\nset -e'
    return sh("#!/bin/bash\n${shellopt}\n${cmd}")
}

def bashOutput(cmd) {
    echo("Running '${cmd}'")
    shellopt = 'set +x\nset -e'
    return sh(script: "#!/bin/bash\n${shellopt}\n${cmd}", returnStdout: true).trim()
}

def cstage(name, doExecute = true, block) {
    return stage(name, doExecute ? block : { echo("Skipped stage ${name}") })
}

def writeOutputArtifact(file_content, output_artifact) {
    writeFile(text: file_content, file: output_artifact)
    archiveArtifacts(artifacts: output_artifact)
}

def save(localDir, fileName, outputArtifactName) {
    httpLink = ""
    s3Link = archive(localDir, fileName)

    // presign with a custom Dockerfile in order to have S3 links longer than 7 days
    docker.withRegistry(REGISTRY_URL) {
        docker.image('awscli').inside {
            httpLink = presignS3Link(s3Link, true)
        }
    }
    writeOutputArtifact(httpLink, outputArtifactName)
}

def archive(localDir, fileName, publish = true) {
    def dstPath = ''
    def s3Path = ''

    if (!params.UPLOAD_BUCKET_PREFIX.isEmpty()) {
        dstPath = "${params.UPLOAD_BUCKET_PREFIX}"
    }
    if (!params.RELEASE_TAG.isEmpty()) {
        dstPath = "${dstPath}/${params.RELEASE_TAG}"
    }
    dstPath = "${dstPath}/${fileName}"

    withAWS(credentials: 'mobile.ci-aws', region: UPLOAD_BUCKET_REGION) {
        s3Path = s3Upload(bucket: params.UPLOAD_BUCKET, verbose: true,
                          file: "${localDir}/${fileName}", path: dstPath)
        if (!s3Path) {
            error("Failed archiving ${fileName}")
        } else if (publish) {
            rtp(parserName: 'HTML',
                stableText: "<li><a href=\"${s3Path}\">S3: ${fileName}</a></li>")
        }
    }
    return s3Path
}

def presignS3Link(s3link, publish = true) {
    def httpPath = ''
    withCredentials([usernamePassword(credentialsId: 'mobile.ci-aws',
                                      usernameVariable: 'AWS_ACCESS_KEY_ID',
                                      passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
        def fileName = s3link.tokenize("/").last()
        def expiration_in_seconds = 365 * 24 * 60 * 60
        httpPath = bashOutput("aws s3 presign --expires-in ${expiration_in_seconds} " +
                               "--region=${params.UPLOAD_BUCKET_REGION} ${s3link}")
        if (publish) {
            rtp(parserName: 'HTML',
                stableText: "<li><a href=\"$httpPath\">HTTPS: $fileName</a></li>")
        }
    }
    return httpPath
}


node {
    REGISTRY_URL = 'https://registry-internal.global.famoco.com:5000'
    def buildImageName = 'famoco/android-sdk-tools-31-jdk11:1.0'
    def appName = 'keyple-plugin-sample-app'

    properties([
            parameters([
                    string(defaultValue: '', name: 'RELEASE_TAG'),
                    string(defaultValue: 'famoco-mob', name: 'UPLOAD_BUCKET'),
                    string(defaultValue: 'keyple-plugin-sample-app-release', name: 'UPLOAD_BUCKET_PREFIX'),
                    string(defaultValue: 'eu-west-1', name: 'UPLOAD_BUCKET_REGION'),
                    booleanParam(defaultValue: false, name: 'SKIP_CLEAN'),
                    booleanParam(defaultValue: false, name: 'SKIP_BUILD'),
                    booleanParam(defaultValue: false, name: 'SKIP_ARCHIVE'),
                    booleanParam(defaultValue: false, name: 'SKIP_SAVE'),
            ])
    ])

    environment {
        AWS_DEFAULT_REGION = ${params.UPLOAD_BUCKET_REGION}
    }

    stage('checkout') {
        checkout scm
    }

    cstage('clean', !params.SKIP_CLEAN) {
        docker.withRegistry(REGISTRY_URL) {
            docker.image(buildImageName).inside {
                sh 'make SKIP_DOCKER=true clean'
            }
        }
    }

    cstage('build', !params.SKIP_BUILD) {
        docker.withRegistry(REGISTRY_URL) {
            docker.image(buildImageName).inside {
                sh 'make SKIP_DOCKER=true appAssembleRelease dist'
            }
        }
    }

    def sourcesArchiveFileName = "${appName}-${RELEASE_TAG}-sources.zip"
    cstage('archive', !params.SKIP_ARCHIVE) {
        bash("git archive --format zip ${RELEASE_TAG} > ${sourcesArchiveFileName}")
    }


    def builtAPKFileName = "${appName}-${RELEASE_TAG}-release.apk"
    cstage('save', !params.SKIP_SAVE) {
        if (!params.SKIP_ARCHIVE) {
            echo "Save source archive : ${sourcesArchiveFileName}"
            save('.', sourcesArchiveFileName, 'keyple_plugin_sample_app_sources_http_url')
        }

        echo "Save built APK : ${builtAPKFileName}"
        save('dist', builtAPKFileName, 'keyple_plugin_sample_app_apk_http_url')
    }
}
