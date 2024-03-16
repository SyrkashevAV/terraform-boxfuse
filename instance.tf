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

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update && apt upgrade && apt install git, default-jdk, maven -y
                sudo echo 1111 && sudo pwd && ls -la && sudo java --version && sudo mvn --version
                git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git
                sudo echo 4444 && sudo pwd && sudo ls -la ~/boxfuse-sample-java-war-hello/
                sudo mvn -f ~/boxfuse-sample-java-war-hello/pom.xml package
              EOF
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
      "sudo echo 5555 && sudo ls -la /var/lib/dpkg/lock-frontend",
      "sudo apt update && apt install default-jdk, tomcat9 -y",
      "sudo apt list --upgradable",
      "sudo echo 6666 && sudo ls -la /var/lib/",
      "sudo echo 7777 && sudo ls -la /var/lib/dpkg",
      "sudo echo 8888 && sudo ls -la /var/lib/dpkg/lock-frontend"
    ]
  }
}
