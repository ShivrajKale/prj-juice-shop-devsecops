pipeline {
    agent any

    environment {
        AWS_REGION       = 'us-east-1'
        ECR_REGISTRY     = '672965014914.dkr.ecr.us-east-1.amazonaws.com'
        ECR_REPO         = 'juice-shop/juice-shop'
        IMAGE_NAME       = "${ECR_REGISTRY}/${ECR_REPO}"
        EKS_CLUSTER      = 'juice-shop-cluster'
        SONAR_PROJECT    = 'juice-shop'
        SLACK_CHANNEL    = '#jenkins-build'

        // Dynamic: set by branch name
        // develop → dev namespace, main → prod namespace
        DEPLOY_ENV       = "${env.BRANCH_NAME == 'main' ? 'prod' : 'dev'}"
        HELM_VALUES_FILE = "${env.BRANCH_NAME == 'main' ? 'values-prod.yaml' : 'values-dev.yaml'}"
    }

    options {
        timeout(time: 45, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {

        // ========================================
        // STAGE 1: CHECKOUT
        // ========================================
        stage('1. Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.IMAGE_TAG = "${env.GIT_COMMIT_SHORT}-${env.BUILD_NUMBER}"
                    echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Deploy target: ${DEPLOY_ENV} namespace"
                }
            }
        }

        // ========================================
        // STAGE 2 + 3: SAST + DEPENDENCY CHECK (PARALLEL)
        // ========================================
        stage('2-3. Security Scans') {
            parallel {

                stage('2. SAST - SonarQube') {
                    steps {
                        withSonarQubeEnv('sonarqube-server') {
                            sh """
                                ${tool 'sonar-scanner'}/bin/sonar-scanner \
                                  -Dsonar.projectKey=${SONAR_PROJECT} \
                                  -Dsonar.sources=. \
                                  -Dsonar.host.url=http://localhost:9000
                            """
                        }
                        // Wait for quality gate result
                        timeout(time: 5, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }

                stage('3. Dependency Check') {
                    steps {
                        sh """
                            dependency-check \
                              --scan . \
                              --format HTML \
                              --format JSON \
                              --out dependency-check-report/ \
                              --project juice-shop \
                              --failOnCVSS 9
                        """
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'dependency-check-report/**', fingerprint: true
                        }
                    }
                }
            }
        }

        // ========================================
        // STAGE 4: DOCKER BUILD
        // ========================================
        stage('4. Docker Build') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        // ========================================
        // STAGE 5: TRIVY IMAGE SCAN
        // ========================================
        stage('5. Trivy Image Scan') {
            steps {
                sh """
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --format table \
                      ${IMAGE_NAME}:${IMAGE_TAG} | tee trivy-table.txt

                    trivy image \
                      --severity HIGH,CRITICAL \
                      --format template \
                      --template "@/usr/local/share/trivy/templates/html.tpl" \
                      --output trivy-report.html \
                      ${IMAGE_NAME}:${IMAGE_TAG} || true
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true, allowEmptyArchive: true
                }
            }
        }

        // ========================================
        // STAGE 6: PUSH TO ECR
        // ========================================
        stage('6. Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                      docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                """
            }
        }

        // ========================================
        // STAGE 7: DEPLOY TO EKS
        // ========================================
        stage('7. Deploy to EKS') {
            steps {
                sh """
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER}

                    helm upgrade --install juice-shop-${DEPLOY_ENV} helm/prj-juice-shop/ \
                      --namespace ${DEPLOY_ENV} \
                      -f helm/prj-juice-shop/${HELM_VALUES_FILE} \
                      --set image.repository=${IMAGE_NAME} \
                      --set image.tag=${IMAGE_TAG} \
                      --wait \
                      --timeout 300s
                """

                // Verify deployment is healthy
                sh """
                    kubectl rollout status deployment/juice-shop-${DEPLOY_ENV} \
                      -n ${DEPLOY_ENV} --timeout=120s

                    echo "=== Pods ==="
                    kubectl get pods -n ${DEPLOY_ENV} -l app=juice-shop

                    echo "=== Service ==="
                    kubectl get svc -n ${DEPLOY_ENV}

                    echo "=== Ingress ==="
                    kubectl get ingress -n ${DEPLOY_ENV}
                """
            }
        }

        // ========================================
        // STAGE 8: DAST - OWASP ZAP
        // ========================================
        stage('8. DAST - OWASP ZAP') {
            steps {
                script {
                    // Get the ALB URL of the deployed application
                    env.APP_URL = sh(
                        script: """
                            kubectl get ingress juice-shop-${DEPLOY_ENV} \
                              -n ${DEPLOY_ENV} \
                              -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
                        """,
                        returnStdout: true
                    ).trim()
                    echo "Scanning: http://${APP_URL}"
                }

                // Wait for ALB to be ready (DNS propagation can take a minute)
                sh """
                    echo "Waiting for ALB to respond..."
                    for i in \$(seq 1 30); do
                        if curl -s -o /dev/null -w "%{http_code}" http://${APP_URL} | grep -q "200"; then
                            echo "ALB is ready!"
                            break
                        fi
                        echo "Attempt \$i/30 - waiting..."
                        sleep 10
                    done
                """

                sh """
                    docker run --rm \
                      -v \${WORKSPACE}/zap-report:/zap/wrk:rw \
                      ghcr.io/zaproxy/zaproxy:stable \
                      zap-baseline.py \
                        -t http://${APP_URL} \
                        -r zap-report.html \
                        -I || true
                """
                // NOTE: -I means don't fail on warnings. Juice Shop is intentionally
                // vulnerable so ZAP WILL find issues. Document this in README.
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap-report/**', fingerprint: true, allowEmptyArchive: true
                }
            }
        }
    }

    // ========================================
    // POST-BUILD ACTIONS
    // ========================================
    post {
        success {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: 'good',
                message: """
                    :white_check_mark: *Pipeline SUCCESS*
                    *Job:* ${env.JOB_NAME} #${env.BUILD_NUMBER}
                    *Branch:* ${env.BRANCH_NAME}
                    *Environment:* ${DEPLOY_ENV}
                    *Image:* ${IMAGE_NAME}:${IMAGE_TAG}
                    *Duration:* ${currentBuild.durationString}
                    <${env.BUILD_URL}|View Build>
                """.stripIndent()
            )
        }
        failure {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                color: 'danger',
                message: """
                    :x: *Pipeline FAILED*
                    *Job:* ${env.JOB_NAME} #${env.BUILD_NUMBER}
                    *Branch:* ${env.BRANCH_NAME}
                    *Stage:* ${env.STAGE_NAME}
                    <${env.BUILD_URL}console|View Console>
                """.stripIndent()
            )
        }
        always {
            // Clean up Docker images to save disk space
            sh """
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${IMAGE_NAME}:latest || true
            """
            cleanWs()
        }
    }
}