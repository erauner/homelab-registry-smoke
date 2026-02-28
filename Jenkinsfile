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
    resources:
      requests: { cpu: "100m", memory: "256Mi" }
      limits:   { cpu: "500m", memory: "512Mi" }
  - name: python
    image: python:3.12-bookworm
    command: ['sleep', '3600']
    resources:
      requests: { cpu: "100m", memory: "256Mi" }
      limits:   { cpu: "500m", memory: "512Mi" }
  - name: golang
    image: golang:1.22
    command: ['sleep', '3600']
    resources:
      requests: { cpu: "200m", memory: "512Mi" }
      limits:   { cpu: "1000m", memory: "1Gi" }
  - name: helm
    image: alpine/helm:3.15.2
    command: ['sleep', '3600']
    resources:
      requests: { cpu: "50m", memory: "128Mi" }
      limits:   { cpu: "250m", memory: "256Mi" }
  - name: curl
    image: curlimages/curl:8.10.1
    command: ['sleep', '3600']
    resources:
      requests: { cpu: "50m", memory: "128Mi" }
      limits:   { cpu: "250m", memory: "256Mi" }
  - name: docker
    image: docker:27-cli
    command: ['sleep', '3600']
    resources:
      requests: { cpu: "100m", memory: "256Mi" }
      limits:   { cpu: "500m", memory: "512Mi" }
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
    booleanParam(name: 'RUN_DOCKER', defaultValue: false, description: 'Enable Docker push/pull check (requires docker daemon access)')
  }

  environment {
    REPOFLOW_BASE_URL = "${params.REPOFLOW_BASE_URL}"
    REPOFLOW_WORKSPACE = "${params.REPOFLOW_WORKSPACE}"
    REPOFLOW_CREDENTIALS = credentials('repoflow-credentials')
    SMOKE_RUN_ID = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(8) ?: 'dev'}"
  }

  stages {
    stage('Validate Inputs') {
      steps {
        echo 'Using Jenkins credential: repoflow-credentials'
      }
    }

    stage('npm') {
      steps {
        container('node') {
          sh 'export REPOFLOW_PAT="$REPOFLOW_CREDENTIALS_PSW"; bash ci/test-npm.sh'
        }
      }
    }

    stage('pypi') {
      steps {
        container('python') {
          sh 'export REPOFLOW_PAT="$REPOFLOW_CREDENTIALS_PSW"; bash ci/test-pypi.sh'
        }
      }
    }

    stage('go') {
      steps {
        container('golang') {
          sh 'apt-get update >/dev/null && apt-get install -y git >/dev/null'
          sh 'export REPOFLOW_PAT="$REPOFLOW_CREDENTIALS_PSW"; bash ci/test-go.sh'
        }
      }
    }

    stage('helm') {
      steps {
        container('helm') {
          sh 'apk add --no-cache bash curl tar gzip >/dev/null'
          sh 'export REPOFLOW_PAT="$REPOFLOW_CREDENTIALS_PSW"; bash ci/test-helm.sh'
        }
      }
    }

    stage('universal') {
      steps {
        container('helm') {
          sh 'apk add --no-cache bash curl tar gzip >/dev/null'
          sh 'export REPOFLOW_PAT="$REPOFLOW_CREDENTIALS_PSW"; bash ci/test-universal.sh'
        }
      }
    }

    stage('docker') {
      when {
        expression { return params.RUN_DOCKER }
      }
      steps {
        container('docker') {
          sh 'export REPOFLOW_PAT="$REPOFLOW_CREDENTIALS_PSW"; bash ci/test-docker.sh'
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
