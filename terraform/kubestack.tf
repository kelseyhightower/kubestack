output "kubernetes-api-server" {
    value = "https://${google_compute_instance.kube-apiserver.network_interface.0.access_config.0.nat_ip}:6443"
}

resource "template_file" "etcd" {
    filename = "etcd.env"
    vars {
        cluster_token = "${var.cluster_name}"
        discovery_url = "${var.discovery_url}"
    }
}

resource "template_file" "kubernetes" {
    filename = "kubernetes.env"
    vars {
        api_servers = "http://${var.cluster_name}-kube-apiserver.c.${var.project}.internal:8080"
        etcd_servers = "${join(",", "${formatlist("http://%s:2379", google_compute_instance.etcd.*.network_interface.0.address)}")}"
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

    name = "${var.cluster_name}-etcd${count.index}"
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
        "sshKeys" = "${var.sshkey_metadata}"
    }

    provisioner "remote-exec" {
        inline = [
            "cat <<'EOF' > /tmp/kubernetes.env\n${template_file.etcd.rendered}\nEOF",
            "echo 'ETCD_NAME=${self.name}' >> /tmp/kubernetes.env",
            "echo 'ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379' >> /tmp/kubernetes.env",
            "echo 'ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380' >> /tmp/kubernetes.env",
            "echo 'ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${self.network_interface.0.address}:2380' >> /tmp/kubernetes.env",
            "echo 'ETCD_ADVERTISE_CLIENT_URLS=http://${self.network_interface.0.address}:2379' >> /tmp/kubernetes.env",
            "sudo mv /tmp/kubernetes.env /etc/kubernetes.env",
            "sudo systemctl enable etcd",
            "sudo systemctl start etcd"
        ]
        connection {
            user = "core"
            agent = true
        }
    }

    depends_on = [
        "template_file.etcd",
    ]
}

resource "google_compute_instance" "kube-apiserver" {
    name = "${var.cluster_name}-kube-apiserver"
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
        "sshKeys" = "${var.sshkey_metadata}"
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
            "sudo mkdir -p /etc/kubernetes",
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
    count = "${var.worker_count}"

    name = "${var.cluster_name}-kube${count.index}"
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
        "sshKeys" = "${var.sshkey_metadata}"
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
