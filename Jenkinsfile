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
      env:
        - name: HTTP_PROXY
          value: http://http.docker.internal:3128
        - name: HTTPS_PROXY
          value: http://http.docker.internal:3128
        - name: NO_PROXY
          value: 127.0.0.1,localhost,.svc,.cluster.local
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
      env:
        - name: HTTP_PROXY
          value: http://http.docker.internal:3128
        - name: HTTPS_PROXY
          value: http://http.docker.internal:3128
        - name: NO_PROXY
          value: 127.0.0.1,localhost,.svc,.cluster.local
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
        - name: HTTP_PROXY
          value: http://http.docker.internal:3128
        - name: HTTPS_PROXY
          value: http://http.docker.internal:3128
        - name: NO_PROXY
          value: 127.0.0.1,localhost,.svc,.cluster.local
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
    - name: kubectl
      image: git-flow-lab-kubectl:v1.36.1
      imagePullPolicy: Never
      command:
        - sleep
      args:
        - 99d
      tty: true
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 250m
          memory: 128Mi
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
                    retry(5) {
                        checkout scm
                    }
                    script {
                        env.IMAGE_TAG = sh(
                            script: 'git rev-parse --short=12 HEAD',
                            returnStdout: true
                        ).trim()
                        env.IMAGE_NAME = "${env.IMAGE_REPOSITORY}:${env.IMAGE_TAG}"
                        echo "Image: ${env.IMAGE_NAME}"
                    }
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
                        retry(5) {
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

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                container('kubectl') {
                    sh '''
                        set -eu

                        kubectl set image \
                          deployment/git-flow-lab \
                          app="$IMAGE_NAME" \
                          --namespace=git-flow-lab

                        kubectl annotate \
                          deployment/git-flow-lab \
                          kubernetes.io/change-cause="Jenkins build $BUILD_NUMBER, commit $IMAGE_TAG" \
                          --namespace=git-flow-lab \
                          --overwrite

                        if ! kubectl rollout status \
                          deployment/git-flow-lab \
                          --namespace=git-flow-lab \
                          --timeout=360s; then
                            kubectl get pods \
                              --namespace=git-flow-lab \
                              --output=wide
                            kubectl get events \
                              --namespace=git-flow-lab \
                              --sort-by=.lastTimestamp
                            exit 1
                        fi

                        kubectl get pods \
                          --namespace=git-flow-lab \
                          --output=wide
                    '''
                }
            }
        }
    }
}
