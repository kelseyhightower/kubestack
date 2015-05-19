provider "google" {
    account_file = "${var.account_file}"
    project = "${var.project}"
    region = "${var.region}"
}

resource "google_compute_firewall" "kubernetes-api" {
    description = "Kubernetes API"
    name = "secure-kubernetes-api"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["6443"]
    }

    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "etcd" {
    count = 3

    name = "etcd${count.index}"
    machine_type = "n1-standard-1"
    can_ip_forward = true
    zone = "${var.zone}"
    tags = ["etcd"]

    disk {
        image = "kubestack-0-0-1-v20150517"
        size = 200
    }

    network_interface {
        network = "default"
        access_config {
            // Ephemeral IP
        }
    }

    metadata {
        "sshKeys" = "${file("sshkey-metadata")}"
    }

    provisioner "file" {
        source = "units/etcd${count.index}.service"
        destination = "/tmp/etcd${count.index}.service"
        connection {
            user = "core"
            agent = true
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/etcd${count.index}.service /etc/systemd/system/etcd.service",
            "sudo systemctl enable etcd",
            "sudo systemctl start etcd",
        ]
        connection {
            user = "core"
            agent = true
        }
    }
}

resource "google_compute_instance" "kube-apiserver" {
    name = "kube-apiserver"
    machine_type = "n1-standard-1"
    can_ip_forward = true
    zone = "${var.zone}"
    tags = ["kubernetes"]

    disk {
        image = "kubestack-server-0-0-1-v20150517"
        size = 200
    }

    network_interface {
        network = "default"
        access_config {
            // Ephemeral IP
        }
    }

    metadata {
        "sshKeys" = "${file("sshkey-metadata")}"
    }

    depends_on = [
        "google_compute_instance.etcd",
    ]
}

resource "google_compute_instance" "kubelet" {
    count = 3

    name = "kube${count.index}"
    can_ip_forward = true
    machine_type = "n1-standard-1"
    zone = "${var.zone}"
    tags = ["kubelet", "kubernetes"]

    disk {
        image = "kubestack-worker-0-0-1-v20150517"
        size = 200
    }

    network_interface {
        network = "default"
        access_config {
            // Ephemeral IP
        }
    }

    metadata {
        "sshKeys" = "${file("sshkey-metadata")}"
    }

    depends_on = [
        "google_compute_instance.kube-apiserver",
    ]
}
