variable "token" {
  description = "Yandex Cloud security OAuth token"
  default     = "y0_AgAAAAACcyKHAATuwQAAAAD49m_piftZgLAFTmuBYzDIbMlhXfAqMxU"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID where resources will be created"
  default     = "b1gf1njbp87lf6un2juk"
}

variable "zone" {
  description = "Zone"
  default = "ru-central1-a"
}

variable "image_id" {
  description = "Specifying id of boot image"
  default = "fd85u0rct32prepgjlv0"
}

variable "disk_size" {
  description = "Specifying disk size"
  default = 10
}

variable "private_key_path" {
  description = "Path to ssh private key, which would be used to access workers"
  default     = "~/.ssh/id_rsa"
}

variable "public_key_path" {
  description = "Path to ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "maven_instance_name" {
  description = "Name prefix for the nodes"
  default = "maven-instance"
}

variable "tomcat_instance_name" {
  description = "Name prefix for the nodes"
  default = "tomcat-instance"
}

variable "num_nodes" {
  description = "Number of nodes to create"
  default = 1
}
