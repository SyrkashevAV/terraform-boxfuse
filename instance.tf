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
  folder_id = "${var.folder_id}"
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

resource "yandex_iam_service_account" "sa" {
  folder_id = "${var.folder_id}"
  name      = "tf-test-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = "${var.folder_id}"
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "test" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "tf-test-bucket-boxfuse"
}

resource "yandex_compute_instance" "build" {
  count = "${var.num_nodes}"
  name = "${var.maven_instance_name}${count.index + 1}"

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }
  resources {
    cores = "${var.cores}"
    memory = "${var.memory}"

  }
  boot_disk {
    initialize_params {
      size  = "${var.disk_size}"
      image_id="${var.image_id}"
      type = "network-ssd"
    }
  }

  connection {
    host = self.network_interface[0].nat_ip_address
    type = "ssh"
    user = "ubuntu"
    agent = false
    private_key = "${file(var.private_key_path)}"
  }

  metadata = {
    ssh-keys = "extor:${file(var.public_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
     "sudo apt update",
     "sudo apt install git default-jdk maven awscli -y",
     "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",
     "mvn -f ~/boxfuse-sample-java-war-hello/pom.xml package",
     "aws --profile default configure set aws_access_key_id ${yandex_iam_service_account_static_access_key.sa-static-key.access_key}",
     "aws --profile default configure set aws_secret_access_key ${nonsensitive(yandex_iam_service_account_static_access_key.sa-static-key.secret_key)}",
     "aws --endpoint-url=https://storage.yandexcloud.net/ s3 cp ~/boxfuse-sample-java-war-hello/target/hello-1.0.war s3://tf-test-bucket-boxfuse/"
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
    cores = "${var.cores}"
    memory = "${var.memory}"
  }
  boot_disk {
    initialize_params {
      size  = "${var.disk_size}"
      image_id="${var.image_id}"
      type = "network-ssd"
    }
  }

  connection {
    host = self.network_interface[0].nat_ip_address
    type = "ssh"
    user = "ubuntu"
    agent = false
    private_key = "${file(var.private_key_path)}"
  }


  metadata = {
    ssh-keys = "extor:${file(var.public_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install default-jdk tomcat9 awscli -y",
      "sleep 180",
      "aws --profile default configure set aws_access_key_id ${yandex_iam_service_account_static_access_key.sa-static-key.access_key}",
      "aws --profile default configure set aws_secret_access_key ${nonsensitive(yandex_iam_service_account_static_access_key.sa-static-key.secret_key)}",
      "aws s3 cp --endpoint-url=https://storage.yandexcloud.net s3://tf-test-bucket-boxfuse/hello-1.0.war hello-1.0.war",
      "sudo mv ./hello-1.0.war /var/lib/tomcat9/webapps/hello-1.0.war",
      "aws s3api delete-object --endpoint-url https://storage.yandexcloud.net --bucket tf-test-bucket-boxfuse --key hello-1.0.war",
      "sudo service tomcat9 restart"
    ]
  }
}
