provider "google" {
    account_file = "/etc/kubestack-account.json"
    project = "kubestack"
    region = "us-central1"
}

resource "google_compute_firewall" "kube-apiserver" {
    description = "Kubernetes API Server Secure Port"
    name = "secure-kube-apiserver"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["6443"]
    }

    source_tags = ["kubernetes", "kube-apiserver"]
    source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "etcd" {
    count = 3

    name = "etcd${count.index}"
    machine_type = "n1-standard-1"
    can_ip_forward = true
    zone = "us-central1-a"
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
        "sshKeys" = "${file("sshkey")}"
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
    zone = "us-central1-a"
    tags = ["kubernetes", "kube-apiserver"]

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
        "sshKeys" = "${file("sshkey")}"
    }

    depends_on = [
        "google_compute_instance.etcd",
    ]
}

resource "google_compute_instance" "kubelet" {
    count = 3

    name = "kubelet${count.index}"
    can_ip_forward = true
    machine_type = "n1-standard-1"
    zone = "us-central1-a"
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
        "sshKeys" = "${file("sshkey")}"
    }

    depends_on = [
        "google_compute_instance.kube-apiserver",
    ]
}
