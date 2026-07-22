pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate README') {
            steps {
                sh '''
                    test -s README.md
                    grep -q '^# Git Flow Lab$' README.md
                '''
            }
        }
    }
}
