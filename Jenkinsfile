pipeline {
    agent {
        kubernetes {
            defaultContainer 'go'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: go
      image: golang:1.26-alpine
      imagePullPolicy: Never
      command:
        - sleep
      args:
        - 99d
      tty: true
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          cpu: 1
          memory: 512Mi
'''
        }
    }

    options {
        skipDefaultCheckout(true)
    }

    stages {
        stage('Checkout') {
            steps {
                container('jnlp') {
                    checkout scm
                }
            }
        }

        stage('Test') {
            steps {
                sh 'go test ./...'
            }
        }

        stage('Build') {
            steps {
                sh '''
                    mkdir -p bin
                    go build -o bin/server .
                    ls -lh bin/server
                '''
            }
        }
    }
}
