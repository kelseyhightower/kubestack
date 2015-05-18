provider "google" {
    account_file = "/etc/kubestack-account.json"
    project = "kubestack"
    region = "us-central1"
}

resource "google_compute_instance" "etcd" {
    name = "etcd${count.index}"
    machine_type = "n1-standard-1"
    zone = "us-central1-a"
    tags = ["etcd"]
    disk {
        image = "kubestack-0-0-1-v20150517"
        size = 200
    }
    can_ip_forward = true
    network_interface {
        network = "default"
        access_config {
            // Ephemeral IP
        }
    }
    metadata {
        "sshKeys" = "${file("sshkey")}"
    }
    count = 3

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
    zone = "us-central1-a"
    tags = ["kubernetes", "kube-apiserver"]
    disk {
        image = "kubestack-server-0-0-1-v20150517"
        size = 200
    }
    can_ip_forward = true
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
    name = "kubelet${count.index}"
    machine_type = "n1-standard-1"
    zone = "us-central1-a"
    tags = ["kubelet", "kubernetes"]
    disk {
        image = "kubestack-worker-0-0-1-v20150517"
        size = 200
    }
    can_ip_forward = true
    network_interface {
        network = "default"
        access_config {
            // Ephemeral IP
        }
    }
    metadata {
        "sshKeys" = "${file("sshkey")}"
    }
    count = 5

    depends_on = [
        "google_compute_instance.kube-apiserver",
    ]
}
