provider "triton" {}

terraform {
  required_version = ">= 0.11.0"
  backend "manta" {
    path = "tsg-consul"
  }
}

resource "triton_machine" "consul_server" {
  count            = "${var.consul_server_count}"
  name             = "${format("tsg-consul-%02d", count.index + 1)}"
  package          = "${var.consul_instance_package}"
  image            = "${data.triton_image.consul_server.id}"

  cns {
    services = ["${var.consul_cns_tag}"]
  }

  tags {
    name = "${format("tsg-consul-%02d", count.index + 1)}"
  }

  affinity    = ["instance!=consul*"]
  user_script = "${element(
                   data.template_file.user_data.*.rendered,
                   count.index)}"

  networks    = ["${data.triton_network.private.id}",
                 "${data.triton_network.public.id}"]
}

data "triton_image" "consul_server" {
  name        = "${var.consul_image_name}"
  version     = "${var.consul_version}"
  most_recent = true
}

data "triton_network" "private" {
  name = "Joyent-SDC-Private"
}

data "triton_network" "public" {
  name = "Joyent-SDC-Public"
}

data "triton_account" "main" {}

data "triton_datacenter" "current" {}

data "template_file" "user_data" {
  count = "${var.consul_server_count}"
  template = "${file("instance-user.conf")}"
  vars {
    hostname = "${format("tsg-consul-%02d", count.index + 1)}"
    dc = "${data.triton_datacenter.current.name}"
    cns_url = "${format("%s.svc.%s.%s.cns.joyent.com", var.consul_cns_tag, data.triton_account.main.id, data.triton_datacenter.current.name)}"
  }
}
