pipeline {
    agent any
    tools{
        terraform 'terraform_v'
    }
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key') // Jenkins credential ID
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    stages {
        stage('Checkout'){
            steps{
                git branch: 'master', url: 'https://github.com/Sagar-Soin/Terraform-KubernetesCluster-Docker-Installation.git'
            }
            
        }
        stage('Terraform Init & Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform validate'
                sh 'terraform fmt'
                sh 'terraform apply -auto-approve'
            }
        }
    }
}

