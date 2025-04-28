pipeline {
    agent any

    environment {
        IMAGE_NAME = "disaster-recovery-backend"
        GIT_BRANCH = "master"
        STATE_FILE_ID = "tfvars-pilot-light-ecr"
        DOCKER_TAG = "backend-latest"
        // These will be populated from terraform
        PRIMARY_REGION = ""
        SECONDARY_REGION = ""
        ECR_REPO_NAME = ""
        AWS_ACCOUNT_ID = ""
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: "${GIT_BRANCH}", url: 'https://github.com/kodwo-essel/spring-catalog.git'
            }
        }

        stage('Build Application') {
            steps {
                script {
                    // Build the Spring Boot application (package the JAR)
                    sh 'mvn clean package -DskipTests'  // Skipping tests for faster builds, change if needed
                }
            }
        }


        stage('Checkout ECR Repository'){
            steps {
                dir('pilot-light-ecr') {
                    git branch: "main", url: 'https://github.com/kodwo-essel/pilot-light-ecr'
                }
            }
        }

        stage('Inject terraform.tfvars') {
            steps {
                withCredentials([file(credentialsId: "${STATE_FILE_ID}", variable: 'TFVARS_FILE')]) {
                    sh "cp -f \"${TFVARS_FILE}\" terraform.tfvars"
                    sh "ls -la"
                    echo 'terraform.tfvars injected.'
                }
            }
        }

        stage('Extract Terraform Variables') {
            steps {
                dir('pilot-light-ecr'){
                    script {
                        // Extract variables from terraform.tfvars
                        def tfvars = readFile('terraform.tfvars').trim()

                        // Parse primary_region
                        def primaryRegionMatch = tfvars =~ /primary_region\s*=\s*"([^"]+)"/
                        if (primaryRegionMatch) {
                            env.PRIMARY_REGION = primaryRegionMatch[0][1]
                            echo "Primary Region: ${env.PRIMARY_REGION}"
                        }

                        // Parse secondary_region
                        def secondaryRegionMatch = tfvars =~ /secondary_region\s*=\s*"([^"]+)"/
                        if (secondaryRegionMatch) {
                            env.SECONDARY_REGION = secondaryRegionMatch[0][1]
                            echo "Secondary Region: ${env.SECONDARY_REGION}"
                        }

                        // Parse ecr_name
                        def ecrNameMatch = tfvars =~ /ecr_name\s*=\s*"([^"]+)"/
                        if (ecrNameMatch) {
                            env.ECR_REPO_NAME = ecrNameMatch[0][1]
                            echo "ECR Repository Name: ${env.ECR_REPO_NAME}"
                        }
                    }
                }

            }
        }

        stage('Handle ECR Creation') {
            steps {
                withCredentials([aws(credentialsId: "aws-credentials")]){
                    dir('pilot-light-ecr') {
                        script {
                            // Now Terraform has AWS credentials available
                            sh 'terraform init'
                            sh 'terraform plan -out=tfplan'
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }

                    script {
                        // Get AWS account ID
                        env.AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query "Account" --output text', returnStdout: true).trim()
                        echo "AWS Account ID: ${env.AWS_ACCOUNT_ID}"
                    }
                }
            }
        }


        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image using the Dockerfile in the repo
                    sh "docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${PRIMARY_REGION}.amazonaws.com/${ECR_REPO_NAME}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    // Use AWS credentials to log in to ECR
                    withCredentials([aws(credentialsId: "aws-credentials")]) {

                        // Get ECR login token and login for primary region
                        sh "aws ecr get-login-password --region ${PRIMARY_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${PRIMARY_REGION}.amazonaws.com"

                        // Push the Docker image to ECR
                        sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${PRIMARY_REGION}.amazonaws.com/${ECR_REPO_NAME}:${DOCKER_TAG}"

                        echo "Image pushed to primary region ECR: ${PRIMARY_REGION}"

                        // Due to your cross-region replication setup, the image will be automatically
                        // replicated to the secondary region by your terraform configuration
                        echo "Image will be replicated to secondary region: ${SECONDARY_REGION}"
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