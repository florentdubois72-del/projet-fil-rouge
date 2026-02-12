// Import de la bibliothèque partagée (si nécessaire)
// @Library('ulrich-shared-library')_

pipeline {
    agent any

    environment {
        // Variables Docker
        DOCKERFILE_NAME = "Dockerfile"
        DOCKER_DIR = "./01_docker"
        DOCKER_IMAGE = "ic-webapp"
        DOCKER_TAG = "1.0"
        DOCKERHUB_ID = "fld72"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
        PORT_APP = "8080"
        PORT_EXT = "8090"
        IP = "172.31.0.71"

        // Variables AWS (utilisées dans plusieurs stages)
        AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
    }

    stages {
        // --- Construction de l'image Docker ---
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        echo "Building Docker image..."
                        docker build --no-cache --network host \
                            -f ${DOCKER_DIR}/${DOCKERFILE_NAME} \
                            -t ${DOCKERHUB_ID}/${DOCKER_IMAGE}:${DOCKER_TAG} \
                            ${DOCKER_DIR}/. || { echo "Build failed"; exit 1; }
                    """
                }
            }
        }

        // --- Lancement et test du container ---
        stage('Run and Test') {
            steps {
                script {
                    sh """
                        echo "Starting container ${DOCKER_IMAGE}..."
                        docker rm -f ${DOCKER_IMAGE} || true
                        docker run --name ${DOCKER_IMAGE} -dp ${PORT_EXT}:${PORT_APP} ${DOCKERHUB_ID}/${DOCKER_IMAGE}:${DOCKER_TAG}

                        # Vérifier que le container est en cours d'exécution
                        if ! docker ps | grep -q ${DOCKER_IMAGE}; then
                            echo "Container failed to start!"
                            docker logs ${DOCKER_IMAGE}
                            exit 1
                        fi

                        # Attendre que l'application réponde
                        MAX_ATTEMPTS=10
                        ATTEMPT=0
                        while ! curl -s http://${IP}:${PORT_EXT} > /dev/null; do
                            if [ \$ATTEMPT -ge \$MAX_ATTEMPTS ]; then
                                echo "Application failed to start in time"
                                docker logs ${DOCKER_IMAGE}
                                exit 1
                            fi
                            sleep 5
                            ATTEMPT=\$((ATTEMPT+1))
                        done

                        # Vérifier le code HTTP
                        curl -I http://${IP}:${PORT_EXT} | grep -i "200"
                    """
                }
            }
        }

        // --- Arrêt et suppression du container ---
        stage('Stop and Delete Container') {
            steps {
                script {
                    sh """
                        echo "Stopping and removing container ${DOCKER_IMAGE}..."
                        docker rm -f ${DOCKER_IMAGE} || true
                    """
                }
            }
        }

        // --- Connexion et push de l'image Docker ---
        stage('Login and Push Image') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub_password', variable: 'DOCKERHUB_PASSWORD')]) {
                        sh """
                            echo "Logging in to DockerHub..."
                            echo \$DOCKERHUB_PASSWORD | docker login -u ${DOCKERHUB_ID} --password-stdin
                            echo "Pushing image to DockerHub..."
                            docker push ${DOCKERHUB_ID}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    }
                }
            }
        }

        // --- Déploiement de l'infrastructure Docker sur AWS ---
        stage('Build Docker EC2') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            steps {
                script {
                    sh """
                        echo "Configuring AWS credentials..."
                        mkdir -p ~/.aws
                        echo "[default]" > ~/.aws/credentials
                        echo "aws_access_key_id=${AWS_ACCESS_KEY_ID}" >> ~/.aws/credentials
                        echo "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" >> ~/.aws/credentials
                        chmod 400 ~/.aws/credentials

                        echo "Initializing Terraform..."
                        cd 02_terraform/
                        terraform init
                        terraform apply -var="stack=docker" -auto-approve
                    """
                }
            }
        }

        // --- Vérification du fichier de configuration Ansible pour Docker ---
        stage('Check File for Docker') {
            agent {
                docker {
                    image 'alpine:latest'
                }
            }
            steps {
                script {
                    sh """
                        echo "Checking Ansible configuration file for Docker..."
                        cat 04_ansible/host_vars/docker.yaml
                    """
                }
            }
        }

        // --- Confirmation avant déploiement sur l'instance Docker ---
        stage('Confirm Deployment on Docker Instance') {
            steps {
                input message: "Confirmez-vous le déploiement sur l'instance Docker ?", ok: 'Oui'
            }
        }

        // --- Déploiement Ansible sur l'instance Docker ---
        stage('Ansible Deploy on Docker Instance') {
            agent {
                docker {
                    image 'registry.gitlab.com/robconnolly/docker-ansible:latest'
                }
            }
            steps {
                script {
                    sh """
                        echo "Deploying with Ansible on Docker instance..."
                        cat 04_ansible/host_vars/docker.yaml
                        cd 04_ansible/
                        ansible docker -m ping --private-key ../02_terraform/keypair/docker.pem
                        ansible-playbook playbooks/docker/main.yaml --private-key ../02_terraform/keypair/docker.pem
                    """
                }
            }
        }

        // --- Confirmation avant destruction de l'instance Docker ---
        stage('Confirm Destroy Docker Instance') {
            steps {
                input message: "Confirmez-vous la suppression de l'instance Docker dans AWS ?", ok: 'Oui'
            }
        }

        // --- Destruction de l'instance Docker sur AWS ---
        stage('Destroy Docker Instance') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            steps {
                script {
                    sh """
                        echo "Destroying Docker instance on AWS..."
                        cd 02_terraform/
                        terraform destroy -var="stack=docker" -auto-approve
                    """
                }
            }
        }

        // --- Déploiement de l'infrastructure Kubernetes sur AWS ---
        stage('Build Kubernetes EC2') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            steps {
                script {
                    sh """
                        echo "Configuring AWS credentials..."
                        mkdir -p ~/.aws
                        echo "[default]" > ~/.aws/credentials
                        echo "aws_access_key_id=${AWS_ACCESS_KEY_ID}" >> ~/.aws/credentials
                        echo "aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" >> ~/.aws/credentials
                        chmod 400 ~/.aws/credentials

                        echo "Initializing Terraform..."
                        cd 02_terraform/
                        terraform init
                        terraform apply -var="stack=kubernetes" -auto-approve
                    """
                }
            }
        }

        // --- Vérification du fichier de configuration Ansible pour Kubernetes ---
        stage('Check File for Kubernetes') {
            agent {
                docker {
                    image 'alpine:latest'
                }
            }
            steps {
                script {
                    sh """
                        echo "Checking Ansible configuration file for Kubernetes..."
                        cat 04_ansible/host_vars/k3s.yaml
                    """
                }
            }
        }

        // --- Confirmation avant déploiement sur le cluster Kubernetes ---
        stage('Confirm Deployment on Kubernetes') {
            steps {
                input message: "Confirmez-vous le déploiement sur le cluster Kubernetes ?", ok: 'Oui'
            }
        }

        // --- Déploiement Ansible sur le cluster Kubernetes ---
        stage('Ansible Deploy on Kubernetes') {
            agent {
                docker {
                    image 'registry.gitlab.com/robconnolly/docker-ansible:latest'
                }
            }
            steps {
                script {
                    sh """
                        echo "Deploying with Ansible on Kubernetes..."
                        cat 04_ansible/host_vars/k3s.yaml
                        cd 04_ansible/
                        ansible k3s -m ping --private-key ../02_terraform/keypair/kubernetes.pem
                        ansible-playbook playbooks/k3s/main.yml --private-key ../02_terraform/keypair/kubernetes.pem
                    """
                }
            }
        }

        // --- Déploiement avec kubectl ---
        stage('Kubectl Deploy') {
            agent {
                docker {
                    image 'bitnami/kubectl'
                    args '--entrypoint=""'
                }
            }
            steps {
                script {
                    sh """
                        echo "Configuring kubectl..."
                        HOST_IP=\$(grep 'ansible_host:' 04_ansible/host_vars/k3s.yaml | awk '{print \$2}')
                        sed -i "s|HOST|\$HOST_IP|g" 03_kubernetes/ic-webapp/ic-webapp-cm.yml

                        echo "Verifying kubeconfig file..."
                        ls -l 04_ansible/playbooks/k3s/kubeconfig-k3s.yml

                        echo "Deploying with kubectl..."
                        kubectl --kubeconfig=04_ansible/playbooks/k3s/kubeconfig-k3s.yml get nodes
                        cd 03_kubernetes/
                        kubectl --kubeconfig=04_ansible/playbooks/k3s/kubeconfig-k3s.yml apply -k . --validate=false -v=9
                    """
                }
            }
        }

        // --- Confirmation avant destruction du cluster Kubernetes ---
        stage('Confirm Destroy Kubernetes EC2') {
            steps {
                input message: "Confirmez-vous la suppression du cluster Kubernetes dans AWS ?", ok: 'Oui'
            }
        }

        // --- Destruction du cluster Kubernetes sur AWS ---
        stage('Destroy Kubernetes EC2') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            steps {
                script {
                    sh """
                        echo "Destroying Kubernetes cluster on AWS..."
                        cd 02_terraform/
                        terraform destroy -var="stack=kubernetes" -auto-approve
                    """
                }
            }
        }
    }

    // --- Nettoyage final (toujours exécuté) ---
    post {
        always {
            script {
                sh """
                    echo "Cleaning up Docker resources..."
                    docker rm -f ${DOCKER_IMAGE} || true
                    docker system prune -f || true
                """
            }
        }
    }
}
