# Pihole Helm chart

Hello wanderer!

This Helm chart is not production ready for sure! I'm using it for my private hybrid Kubernetes cluster based on K3s. I wasn't happy with other Helm charts for pihole that I've found.
I plan to keep this updated, as pihole is an essential part of my private "cloud" and I need to ensure that the latest and greatest version is always deployed on my system.

# Example deployment

## Values

Below you can find the `values.yaml` file that is similar to what I'm using

```yaml
ingress:
  className: nginx
  enabled: true
  hosts:
    - host: "pihole.example.com"
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

pvc:
  etc_pihole:
    storageClassName: ""
    size: 1Gi
  etc_dnsmasqd:
    storageClassName: ""
    size: 1Gi

dnsTcpOnHost:
  enabled: true
  hostIP: "10.0.0.10"

dnsUdpOnHost:
  enabled: true
  hostIP: "10.0.0.10"
```

As you can see, I'm using ingress-nginx controller (outside of the scope for this chart) for the Web UI and I'm also exposing DNS ports on the host where pihole is running.

## Installation

After creating the `values.yaml` file, you can install this chart:

```bash
helm install -n pihole --create-namespace pihole https://github.com/artur-borys/pihole-helm/releases/download/0.1.0/pihole-0.1.0.tgz -f values.yaml
```
