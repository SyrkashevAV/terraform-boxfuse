pipeline {
  agent {
    environment {
      NEXUS_URL = "51.250.74.132:8123"
      USERNAME = "admin"
    }

    docker {
      image '${NEXUS_URL}/boxfuse:1.0'
      args '-v /var/run/docker.sock:/var/run/docker.sock'
    }

  tools {
          maven 'm3'
  }

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
                withCredentials([usernamePassword(credentialsId: 'docker-registry', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                  sh 'docker login ${NEXUS_URL} -u $USERNAME -p $PASSWORD'

                withDockerRegistry(credentialsId: '62d1263a-54b8-467a-8e76-002cc88115e9', url: 'https://index.docker.io/v1/') {
                  sh 'docker push grandhustla/homework11-project:1.0.0'

                withCredentials([usernamePassword(credentialsId: '26f2ddee-0e23-4038-8234-1f59b4582679', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh 'docker login 158.160.38.190:8081 -u $NEXUS_USERNAME -p $NEXUS_PASSWORD'

                sh 'docker tag mywebapp:v5.0 ${NEXUS_URL}/mywebapp:v5.0'
                sh 'docker push ${NEXUS_URL}/mywebapp:v5.0'
                sh 'docker run -d -p 8080:8080 mywebapp:v5.0'
        }
    }


    stage('Deploy to Production') {
      steps {
            deploy adapters: [tomcat9(credentialsId: 'f7a2c7a4-9c67-49c4-8d5e-2c775e33c9c9', path:  '', url: 'http://65.0.125.40:8080/')], contextPath: 'myweb', war: 'target/*.war'
            }
      }
    }
  }
}
