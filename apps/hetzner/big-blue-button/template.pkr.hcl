
variable "app_name" {
  type    = string
  default = "big-blue-button"
}

variable "app_version" {
  type    = string
  default = "2.3.0"
}

variable "hcloud_image" {
  type    = string
  default = "ubuntu-18.04"
}

variable "apt_packages" {
  type    = string
  default = "nginx certbot python-certbot-nginx haveged openjdk-8-jdk"
}

variable "git-sha" {
  type    = string
  default = "${env("GITHUB_SHA")}"
}

variable "hcloud_api_token" {
  type      = string
  default   = "${env("HCLOUD_API_TOKEN")}"
  sensitive = true
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "hcloud" "autogenerated_1" {
  image       = "${var.hcloud_image}"
  location    = "nbg1"
  server_name = "hcloud-app-builder-${var.app_name}-${local.timestamp}"
  server_type = "cx21"
  snapshot_labels = {
    app       = "${var.app_name}"
    git-sha   = "${var.git-sha}"
    version   = "${var.app_version}"
    slug      = "oneclick-${var.app_name}-${var.app_version}-${var.hcloud_image}"
  }
  snapshot_name = "hcloud-app-${var.app_name}-${local.timestamp}"
  ssh_username  = "root"
  token         = "${var.hcloud_api_token}"
}

build {
  sources = ["source.hcloud.autogenerated_1"]

  provisioner "shell" {
    inline = ["cloud-init status --wait"]
  }

  provisioner "file" {
    destination = "/opt/"
    source      = "apps/hetzner/big-blue-button/files/opt/"
  }

  provisioner "file" {
    destination = "/usr/"
    source      = "apps/hetzner/big-blue-button/files/usr/"
  }

  provisioner "file" {
    destination = "/var/"
    source      = "apps/hetzner/big-blue-button/files/var/"
  }

  provisioner "file" {
    destination = "/var/www/"
    source      = "apps/shared/www/"
  }

  provisioner "file" {
    destination = "/var/www/html/assets/"
    source      = "apps/hetzner/big-blue-button/images/"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    scripts          = ["apps/shared/scripts/apt-upgrade.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    inline           = ["apt -qqy -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install ${var.apt_packages}"]
  }

  provisioner "shell" {
    environment_vars = ["application_version=${var.app_version}", "DEBIAN_FRONTEND=noninteractive", "LC_ALL=C", "LANG=en_US.UTF-8", "LC_CTYPE=en_US.UTF-8"]
    scripts          = ["apps/hetzner/big-blue-button/scripts/bbb-install.sh", "apps/shared/scripts/cleanup.sh"]
  }

  provisioner "file" {
    destination = "/etc/"
    source      = "apps/hetzner/big-blue-button/files/etc/"
  }

}