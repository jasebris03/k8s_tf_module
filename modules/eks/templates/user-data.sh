#!/bin/bash
set -o xtrace

# EKS Node Group Bootstrap Script
# This script configures the node to join the EKS cluster

# Install required packages
yum install -y amazon-efs-utils

# Configure kubelet
mkdir -p /etc/eks
cat > /etc/eks/bootstrap.sh << 'EOF'
#!/bin/bash
set -o xtrace

# EKS Bootstrap Script
# This script is used to bootstrap the node and join the cluster

# Set the cluster name
CLUSTER_NAME="${cluster_name}"

# Set the cluster endpoint
CLUSTER_ENDPOINT="${cluster_endpoint}"

# Set the cluster CA certificate
CLUSTER_CA_CERTIFICATE="${cluster_ca_certificate}"

# Configure kubelet
cat > /etc/eks/kubelet-config.json << 'KUBELET_CONFIG'
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "address": "0.0.0.0",
  "authentication": {
    "anonymous": {
      "enabled": false
    },
    "webhook": {
      "cacheTTL": "2m0s",
      "enabled": true
    },
    "x509": {
      "clientCAFile": "/etc/kubernetes/pki/ca.crt"
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "clusterDomain": "cluster.local",
  "hairpinMode": "hairpin-veth",
  "cgroupDriver": "systemd",
  "cgroupRoot": "/",
  "featureGates": {
    "RotateKubeletServerCertificate": true
  },
  "serializeImagePulls": false,
  "serverTLSBootstrap": true,
  "tlsCipherSuites": [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
    "TLS_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_RSA_WITH_AES_128_GCM_SHA256"
  ],
  "maxPods": 110
}
KUBELET_CONFIG

# Start kubelet
/etc/eks/bootstrap.sh ${cluster_name} \
  --kubelet-config /etc/eks/kubelet-config.json \
  --apiserver-endpoint ${cluster_endpoint} \
  --b64-cluster-ca ${cluster_ca_certificate} \
  --container-runtime containerd \
  --dns-cluster-ip 10.100.0.10 \
  --use-max-pods false

# Configure containerd
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml << 'CONTAINERD_CONFIG'
version = 2
root = "/var/lib/containerd"
state = "/run/containerd"

[grpc]
  address = "/run/containerd/containerd.sock"
  uid = 0
  gid = 0

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/pause:3.5"
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    enable_selinux = false
    enable_tls_streaming = false
    max_container_log_line_size = 16384

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      snapshotter = "overlayfs"
      disable_snapshot_annotations = true

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true

    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/cni/bin"
      conf_dir = "/etc/cni/net.d"
      max_conf_num = 1

    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.us-west-2.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.us-west-2.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.us-east-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.us-east-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.us-east-2.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.us-east-2.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.eu-west-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.eu-west-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.eu-west-2.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.eu-west-2.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.eu-west-3.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.eu-west-3.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.eu-north-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.eu-north-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.eu-central-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.eu-central-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.ap-northeast-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.ap-northeast-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.ap-south-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.ap-south-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.sa-east-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.sa-east-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.ca-central-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.ca-central-1.amazonaws.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.cn-north-1.amazonaws.com.cn"]
          endpoint = ["https://602401143452.dkr.ecr.cn-north-1.amazonaws.com.cn"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.cn-northwest-1.amazonaws.com.cn"]
          endpoint = ["https://602401143452.dkr.ecr.cn-northwest-1.amazonaws.com.cn"]

CONTAINERD_CONFIG

# Restart containerd
systemctl restart containerd

# Start kubelet
systemctl enable kubelet
systemctl start kubelet
EOF

chmod +x /etc/eks/bootstrap.sh

# Run the bootstrap script
/etc/eks/bootstrap.sh 