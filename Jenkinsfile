pipeline {
    agent {
        kubernetes {
            defaultContainer 'go'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: cicd-deployer
  volumes:
    - name: buildkit-state
      emptyDir: {}
  containers:
    - name: jnlp
      image: jenkins/inbound-agent:3384.v60d89463d9e0-1
      imagePullPolicy: Never
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          memory: 512Mi
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
    - name: buildkit
      image: moby/buildkit:v0.31.2-rootless
      imagePullPolicy: Never
      command:
        - sleep
      args:
        - 99d
      tty: true
      env:
        - name: BUILDKITD_FLAGS
          value: --oci-worker-no-process-sandbox
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: Unconfined
        appArmorProfile:
          type: Unconfined
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 2
          memory: 2Gi
      volumeMounts:
        - name: buildkit-state
          mountPath: /home/user/.local/share/buildkit
'''
        }
    }

    environment {
        IMAGE_REPOSITORY = 'ghcr.io/phantanlong645-netizen/git-flow-lab'
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
                script {
                    env.IMAGE_TAG = env.GIT_COMMIT.take(12)
                    env.IMAGE_NAME = "${env.IMAGE_REPOSITORY}:${env.IMAGE_TAG}"
                    echo "Image: ${env.IMAGE_NAME}"
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

        stage('Archive Binary') {
            steps {
                archiveArtifacts artifacts: 'bin/server', fingerprint: true
            }
        }

        stage('Build and Push Image') {
            when {
                branch 'main'
            }
            steps {
                container('buildkit') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'ghcr-credentials',
                            usernameVariable: 'GHCR_USER',
                            passwordVariable: 'GHCR_TOKEN'
                        )
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            export DOCKER_CONFIG="$WORKSPACE/.docker"
                            mkdir -p "$DOCKER_CONFIG"
                            trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                            AUTH="$(printf '%s:%s' "$GHCR_USER" "$GHCR_TOKEN" | base64 | tr -d '\\n')"
                            printf '{"auths":{"ghcr.io":{"auth":"%s"}}}\\n' "$AUTH" > "$DOCKER_CONFIG/config.json"

                            buildctl-daemonless.sh build \
                              --frontend dockerfile.v0 \
                              --local context=. \
                              --local dockerfile=. \
                              --opt "build-arg:VERSION=$IMAGE_TAG" \
                              --output "type=image,name=$IMAGE_NAME,push=true"
                        '''
                    }
                }
            }
        }
    }
}
