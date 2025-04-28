pipeline {
    agent any

    environment {
        IMAGE_NAME = "disaster-recovery-backend"
        DOCKER_REGISTRY = "docker.io"
        DOCKER_REPO = "kodwoessel"
        DOCKER_TAG = "latest"
        GIT_BRANCH = "main"
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: "${GIT_BRANCH}", url: 'https://github.com/kodwo-essel/catalog.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    // Use Maven to install dependencies for Spring Boot
                    sh 'mvn clean install'  // Use 'gradle build' if you are using Gradle
                }
            }
        }

        stage('Build Application') {
            steps {
                script {
                    // Build the Spring Boot application (package the JAR)
                    sh 'mvn package -DskipTests'  // Skipping tests for faster builds, change if needed
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image using the Dockerfile in the repo
                    sh "docker build -t ${DOCKER_REGISTRY}/${DOCKER_REPO}/${IMAGE_NAME}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Use Jenkins credentials to log in to Docker
                    withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        // Log in to Docker registry
                        sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'

                        // Push the Docker image to the registry
                        sh "docker push ${DOCKER_REGISTRY}/${DOCKER_REPO}/${IMAGE_NAME}:${DOCKER_TAG}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
