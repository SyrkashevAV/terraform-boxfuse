terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = "${var.token}"
  folder_id = var.folder_id
  zone      = "${var.zone}"
  profile   = "testing"
}

resource "yandex_vpc_network" "network" {
  name = "network1"

  labels = {
    environment = "network"
  }
}

resource "yandex_vpc_subnet" "subnet" {
  name = "subnet1"
  zone = "${var.zone}"
  network_id = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.0.0/24"]

  labels = {
    environment = "subnet"
  }
}

resource "yandex_compute_instance" "build" {
  count = "${var.num_nodes}"
  name = "${var.maven_instance_name}${count.index + 1}"

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }
  resources {
    cores = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      size  = "${var.disk_size}"
      image_id="fd85u0rct32prepgjlv0"
      type = "network-ssd"
    }
  }

  connection {
    host = self.network_interface[0].nat_ip_address
    type = "ssh"
    user = "ubuntu"
    agent = false
    private_key = file("~/.ssh/id_rsa")
  }

  metadata = {
    ssh-keys = "extor:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "remote-exec" {
    inline = [
     "sudo apt-get update && apt get upgrade && apt install git, default-jdk, awscli -y",
     "sudo echo 111111 && sudo pwd && ls -la && java --version",
     "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
     "sudo echo 222222 && sudo pwd && sudo ls -la ~/boxfuse-sample-java-war-hello/",
     "sudo wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz",
     "sudo echo 8888 && ls -la ~/",
     "sudo echo 9999 && ls -la /opt/",
     "sudo tar xvf ~/apache-maven-3.9.6-bin.tar.gz -C /opt",
     "sudo echo 9999999999 && ls -la /opt/",
     "sudo echo 'export M2_HOME=/opt/apache-maven-3.9.6' >> ~/.profile",
     "sudo echo 'export M2=$M2_HOME/bin' >> ~/.profile",
     "sudo echo 'export MAVEN_OPTS="-Xms256m -Xmx512m"' >> ~/.profile",
     "sudo echo 'export PATH=$M2:$PATH' >> ~/.profile",
     "sudo source ~/.profile",
     "sudo cat ~/.profile",
     "sudo mvn --version",
     "sudo echo 77777 && sudo ls -la ~/",
     "sudo mvn --version",
     "mvn -f ~/boxfuse-sample-java-war-hello/pom.xml package",
     "sudo echo 333333 && sudo pwd && sudo ls -la ~/boxfuse-sample-java-war-hello",
     "sudo echo 444444 && sudo pwd && sudo ls -la ~/",
     "cp /tmp/boxfuse/target/hello-1.0.war s3://devupprod.test.com --acl public-read"
    ]
  }
}

resource "yandex_compute_instance" "prod" {
  count = "${var.num_nodes}"
  name = "${var.tomcat_instance_name}${count.index + 1}"

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }
  resources {
    cores = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      size  = "${var.disk_size}"
      image_id="fd85u0rct32prepgjlv0"
      type = "network-ssd"
    }
  }

  connection {
    host = self.network_interface[0].nat_ip_address
    type = "ssh"
    user = "ubuntu"
    agent = false
    private_key = file("~/.ssh/id_rsa")
  }


  metadata = {
    ssh-keys = "extor:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && apt install default-jdk, tomcat9, awscli -y",
      "sudo echo 55555 && sudo pwd && sudo ls -la /usr/lib",
      "sudo echo 66666 && sudo pwd && sudo ls -la /usr/local",
      "cd /var/lib/tomcat9/webapps/",
      "sleep 180",
      "sudo wget https://s3.eu-central-1.amazonaws.com/devupprod.test.com/hello-1.0.war",
      "sudo service tomcat9 restart"
    ]
  }
}
