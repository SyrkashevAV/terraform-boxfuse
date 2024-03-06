pipeline {
  agent {
    docker {
      image 'syrkashevav/boxfuse:v1.0'
    }
  }

  environment {
    NEXUS_URL = "158.160.106.226:8123"
    PRODE = "178.154.200.198"
    USERNAME = "admin"
    PASSWORD = "admin"
  }

  tools {
          maven 'm3'
  }

  stages {

    stage('git clone builder') {
      steps {
        git 'https://github.com/boxfuse/boxfuse-sample-java-war-hello.git'
        sh 'pwd'
        sh 'ls -la'
      }
    }

    stage('Build image') {
      steps {
        sh 'pwd'
        sh 'ls -la'
        sh 'mvn package'
      }
    }

    stage('Build dockerfile, push to Nexus and run docker') {
      steps {
        git 'https://github.com/SyrkashevAV/jenkins-pipeline.git'
        sh 'pwd'
        sh 'ls -la'
        sh 'docker build --tag=mywebapp:v5.0 -f dockerfile.prod -t .'
      }
    }

    stage("Login, push to Nexus ") {
        steps {
                withCredentials([usernamePassword(credentialsId: '2bf3b32f-9aef-4dad-ae85-7aaecbb9c4c9', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                sh 'docker login ${NEXUS_URL} -u $USERNAME -p $PASSWORD'

                sh 'docker tag mywebapp:v5.0 ${NEXUS_URL}/mywebapp:v5.0'
                sh 'docker push ${NEXUS_URL}/mywebapp:v5.0'
                sh 'docker run -d -p 8080:8080 mywebapp:v5.0'
              }
        }
    }

    stage('Deploy to Production') {
      steps {
            deploy adapters: [tomcat9(credentialsId: '43bd4659-ebc3-40f1-ba49-1d219980b31d', path: '', url: 'http://178.154.200.198:8080')], contextPath: 'mywebapp:v5.0', war: 'target/*.war'
      }
    }
 }
}
