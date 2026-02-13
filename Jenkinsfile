// /* import shared library. */
// @Library('ulrich-shared-library')_

pipeline {
    agent any
    environment {
        DOCKERFILE_NAME = "Dockerfile"
        DOCKER_DIR = "./01_docker"
        DOCKER_IMAGE = "ic-webapp"
        DOCKER_TAG = "1.0"
        DOCKERHUB_ID = "fld72"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
        PORT_APP = "8080"
        PORT_EXT = "8090"
        IP = "172.31.0.71"
    }
    stages {
        stage('Build Image'){
            steps{
                script {
                    sh '''
                        docker build --no-cache --network host -f ${DOCKER_DIR}/${DOCKERFILE_NAME} -t ${DOCKERHUB_ID}/${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_DIR}/.
                    '''
                }
            }
        }
        stage('Run and Test'){
            steps{
                script {
                    sh '''
                        docker ps -a | grep -i ${DOCKER_IMAGE} && docker rm -f  ${DOCKER_IMAGE}
                        docker run --name ${DOCKER_IMAGE} -dp $PORT_EXT:$PORT_APP ${DOCKERHUB_ID}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 5
                        curl -I http://$IP:$PORT_EXT | grep -i "200"
                    '''
                }
            }
        }
        stage('Stop and Delete Container') {
            steps{
                script {
                    sh '''
                        docker ps -a | grep -i ${DOCKER_IMAGE} && docker rm -f  ${DOCKER_IMAGE}
                    '''
                }
            }
        }
        stage('Login and Push Image'){
            steps{
                script {
                    // Dockerhub Registry
                    sh '''
                        echo $DOCKERHUB_PASSWORD | docker login -u ${DOCKERHUB_ID} --password-stdin
                        docker push ${DOCKERHUB_ID}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                    // Github Registry
                    // sh '''
                    //     echo $DOCKERHUB_PASSWORD | docker login ghcr.io -u $DOCKERHUB_ID --password-stdin
                    // '''
                }
            }
        }
        stage('Build Docker EC2'){
            environment{
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
            }
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            steps{
                script {
                    sh '''
                        mkdir -p ~/.aws
                        echo "[default]" > ~/.aws/credentials
                        echo -e "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
                        echo -e "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
                        chmod 400 ~/.aws/credentials
                        cd 02_terraform/
                        terraform init 
                        terraform apply -var="stack=docker" -auto-approve
                    '''
                }
            }
        }
        // stage('Docker ec2') {
        //     agent {
        //         docker {
        //             image 'jenkins/jnlp-agent-terraform'
        //         }
        //     }
        //     environment {
        //         AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        //         AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        //     }
        //     steps {
        //         script {
        //             sh '''
        //                 echo "Generating aws credentials"
        //                 echo "Deleting older if exist"
        //                 mkdir -p ~/.aws
        //                 echo "[default]" > ~/.aws/credentials
        //                 echo -e "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
        //                 echo -e "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
        //                 chmod 400 ~/.aws/credentials
        //                 cd "./02_terraform/"
        //                 terraform init 
        //                 terraform apply --var="stack=docker" --auto-approve
        //             '''
        //         }
        //     }
        // }
        stage('Check File for docker') {
            agent { docker { image 'alpine:latest' } }
            steps {
                script {
                    // Vérification que les modifications dans le fichier sont présentes dans ce stage
                    sh '''
                        echo "Checking file in Check File stage..."
                        cat  "04_ansible/host_vars/docker.yaml"
                    '''
                }
            }
        }
        stage('deploy on docker instance') {
            steps {
                input message: "Confirmer vous le deploiement Sur l'instance Docker ?", ok: 'Yes'
            }
        }
        stage('ansible deploy on  Docker instance'){
            agent {
                docker {
                    image  'registry.gitlab.com/robconnolly/docker-ansible:latest'
                }
            }
            steps{
                script {
                    sh '''
                        cat  "04_ansible/host_vars/docker.yaml"
                        cd "04_ansible/"
                        ansible docker -m ping --private-key ../02_terraform/keypair/docker.pem
                        ansible-playbook playbooks/docker/main.yaml --private-key ../02_terraform/keypair/docker.pem
                    '''
                }
            }
        }
        
        stage('destroy Docker instance on AWS with terraform') {
            steps {
                input message: "Confirmer vous la suppression de l'instance Docker  dans AWS ?", ok: 'Yes'
            }
        }

        stage('destroy Docker instance') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
            }
            steps {
                script {
                    sh '''
                        cd "./02_terraform/"
                        terraform destroy --var="stack=docker" --auto-approve
                    '''
                }
            }
        }
        stage('kubernetes ec2') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
            }
            steps {
                script {
                    sh '''
                        echo "Generating aws credentials"
                        echo "Deleting older if exist"
                        mkdir -p ~/.aws
                        echo "[default]" > ~/.aws/credentials
                        echo -e "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
                        echo -e "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
                        chmod 400 ~/.aws/credentials
                        cd "./02_terraform/"
                        terraform init 
                        terraform apply --var="stack=kubernetes" --auto-approve
                    '''
                }
            }
        }
        stage('Check File for k3s') {
            agent { docker { image 'alpine:latest' } }
            steps {
                script {
                    // Vérification que les modifications dans le fichier sont présentes dans ce stage
                    sh '''
                        echo "Checking file in Check File stage..."
                        cat  "04_ansible/host_vars/k3s.yaml"  
                    '''
                }
            }
        }
        stage('deploy on kubernetes cluster') {
            steps {
                input message: "Confirmer vous le deploiement dans AWS ?", ok: 'Yes'
            }
        }
        stage('ansible deploy on  kubernetes'){
            agent {
                docker {
                    image  'registry.gitlab.com/robconnolly/docker-ansible:latest'
                }
            }
            steps{
                script {
                    sh '''
                        cat  "04_ansible/host_vars/k3s.yaml"
                        cd "04_ansible/"
                        ansible k3s -m ping --private-key ../02_terraform/keypair/kubernetes.pem
                        ansible-playbook playbooks/k3s/main.yml --private-key ../02_terraform/keypair/kubernetes.pem
                    '''
                }
            }
        }
        stage('kubectl deploy'){
            agent {
                docker {
                    image 'bitnami/kubectl'
                    args '--entrypoint=""'
                }
            }
            steps {
                script {
                    sh '''
                        HOST_IP=$(grep 'ansible_host:' 04_ansible/host_vars/k3s.yaml | awk '{print $2}')
                        sed -i "s|HOST|$HOST_IP|g" 03_kubernetes/ic-webapp/ic-webapp-cm.yml
                        echo "Verifying kubeconfig file..."
                        ls -l 04_ansible/playbooks/k3s/kubeconfig-k3s.yml
                        echo "Checking cluster access..."
                        kubectl --kubeconfig=04_ansible/playbooks/k3s/kubeconfig-k3s.yml get nodes
                        cd $(pwd)/03_kubernetes/
                        kubectl --kubeconfig=$(pwd)/../04_ansible/playbooks/k3s/kubeconfig-k3s.yml apply -k . --validate=false -v=9
                    '''
                }
            }
        }
        stage('destroy EC2 on AWS with terraform') {
            steps {
                input message: "Confirmer vous la suppression de la dev dans AWS ?", ok: 'Yes'
            }
        }
        stage('destroy kubernetes EC2') {
            agent {
                docker {
                    image 'jenkins/jnlp-agent-terraform'
                }
            }
            environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
            }
            steps {
                script {
                    sh '''
                        cd "./02_terraform/"
                        terraform destroy --var="stack=kubernetes" --auto-approve
                    '''
                }
            }
        }
    }
}
// post{
//     always {
//         script {
//             slackNotifier currentBuild.result
//         }
//     }
// }    

