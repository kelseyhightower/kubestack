resource "template_file" "kubernetes" {
    filename = "kubernetes.env"
    vars {
        api_servers = "http://kube-apiserver.c.${var.project}.internal:8080"
        etcd_servers = "http://etcd0.c.${var.project}.internal:2379,http://etcd1.c.${var.project}.internal:2379,http://etcd2.c.${var.project}.internal:2379"
        flannel_backend = "${var.flannel_backend}"
        flannel_network = "${var.flannel_network}"
        portal_net = "${var.portal_net}"
    }
}

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
        image = "${var.image}"
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
    
    depends_on = [
        "template_file.kubernetes",
    ]
}

resource "google_compute_instance" "kube-apiserver" {
    name = "kube-apiserver"
    machine_type = "n1-standard-1"
    can_ip_forward = true
    zone = "${var.zone}"
    tags = ["kubernetes"]

    disk {
        image = "${var.image}"
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
        source = "${var.token_auth_file}"
        destination = "/tmp/tokens.csv"
        connection {
            user = "core"
            agent = true
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo cat <<'EOF' > /tmp/kubernetes.env\n${template_file.kubernetes.rendered}\nEOF",
            "sudo mv /tmp/kubernetes.env /etc/kubernetes.env",
            "sudo mv /tmp/tokens.csv /etc/kubernetes/tokens.csv",
            "sudo systemctl enable flannel",
            "sudo systemctl enable docker",
            "sudo systemctl enable kube-apiserver",
            "sudo systemctl enable kube-controller-manager",
            "sudo systemctl enable kube-scheduler",
            "sudo systemctl start flannel",
            "sudo systemctl start docker",
            "sudo systemctl start kube-apiserver",
            "sudo systemctl start kube-controller-manager",
            "sudo systemctl start kube-scheduler"
        ]
        connection {
            user = "core"
            agent = true
        }
    }

    depends_on = [
        "google_compute_instance.etcd",
        "template_file.kubernetes",
    ]
}

resource "google_compute_instance" "kube" {
    count = 3

    name = "kube${count.index}"
    can_ip_forward = true
    machine_type = "n1-standard-1"
    zone = "${var.zone}"
    tags = ["kubelet", "kubernetes"]

    disk {
        image = "${var.image}"
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

    provisioner "remote-exec" {
        inline = [
            "sudo cat <<'EOF' > /tmp/kubernetes.env\n${template_file.kubernetes.rendered}\nEOF",
            "sudo mv /tmp/kubernetes.env /etc/kubernetes.env",
            "sudo systemctl enable flannel",
            "sudo systemctl enable docker",
            "sudo systemctl enable kube-kubelet",
            "sudo systemctl enable kube-proxy",
            "sudo systemctl start flannel",
            "sudo systemctl start docker",
            "sudo systemctl start kube-kubelet",
            "sudo systemctl start kube-proxy"
        ]
        connection {
            user = "core"
            agent = true
        }
    }

    depends_on = [
        "google_compute_instance.kube-apiserver",
        "template_file.kubernetes"
    ]
}
