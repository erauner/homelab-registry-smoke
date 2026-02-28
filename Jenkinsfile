@Library('homelab') _

pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    workload-type: ci-builds
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:3355.v388858a_47b_33-3-jdk21
    resources:
      requests: { cpu: "100m", memory: "256Mi" }
      limits:   { cpu: "500m", memory: "512Mi" }
  - name: node
    image: node:20-bookworm
    command: ['sleep', '3600']
  - name: python
    image: python:3.12-bookworm
    command: ['sleep', '3600']
  - name: golang
    image: golang:1.22
    command: ['sleep', '3600']
  - name: helm
    image: alpine/helm:3.15.2
    command: ['sleep', '3600']
  - name: curl
    image: curlimages/curl:8.10.1
    command: ['sleep', '3600']
  - name: docker
    image: docker:27-cli
    command: ['sleep', '3600']
'''
    }
  }

  options {
    timeout(time: 30, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    string(name: 'REPOFLOW_BASE_URL', defaultValue: 'https://repoflow.erauner.dev', description: 'RepoFlow base URL')
    string(name: 'REPOFLOW_WORKSPACE', defaultValue: 'homelab', description: 'RepoFlow workspace name')
    password(name: 'REPOFLOW_PAT', defaultValue: '', description: 'RepoFlow personal access token')
    booleanParam(name: 'RUN_DOCKER', defaultValue: false, description: 'Enable Docker push/pull check (requires docker daemon access)')
  }

  environment {
    REPOFLOW_BASE_URL = "${params.REPOFLOW_BASE_URL}"
    REPOFLOW_WORKSPACE = "${params.REPOFLOW_WORKSPACE}"
    REPOFLOW_PAT = "${params.REPOFLOW_PAT}"
    SMOKE_RUN_ID = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(8) ?: 'dev'}"
  }

  stages {
    stage('Validate Inputs') {
      steps {
        script {
          if (!params.REPOFLOW_PAT?.trim()) {
            error('REPOFLOW_PAT is required')
          }
        }
      }
    }

    stage('npm') {
      steps {
        container('node') {
          sh 'bash ci/test-npm.sh'
        }
      }
    }

    stage('pypi') {
      steps {
        container('python') {
          sh 'bash ci/test-pypi.sh'
        }
      }
    }

    stage('go') {
      steps {
        container('golang') {
          sh 'apt-get update >/dev/null && apt-get install -y git >/dev/null'
          sh 'bash ci/test-go.sh'
        }
      }
    }

    stage('helm') {
      steps {
        container('helm') {
          sh 'apk add --no-cache bash curl tar gzip >/dev/null'
          sh 'bash ci/test-helm.sh'
        }
      }
    }

    stage('universal') {
      steps {
        container('helm') {
          sh 'apk add --no-cache bash curl tar gzip >/dev/null'
          sh 'bash ci/test-universal.sh'
        }
      }
    }

    stage('docker') {
      when {
        expression { return params.RUN_DOCKER }
      }
      steps {
        container('docker') {
          sh 'bash ci/test-docker.sh'
        }
      }
    }
  }

  post {
    success {
      echo 'RepoFlow smoke checks passed'
    }
    failure {
      script {
        homelab.notifyDiscord(status: 'FAILURE')
      }
    }
  }
}
