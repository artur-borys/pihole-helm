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

auth:
  # Password to the Web UI
  password: "<<base64 encoded password here>"
  # secretName: "<<name of the secret containing "webpassword" key>"

dnsTcpOnHost:
  enabled: true
  hostIP: "10.0.0.10"

dnsUdpOnHost:
  enabled: true
  hostIP: "10.0.0.10"

# You can set your adlists here
# They will be loaded on the FIRST startup automatically
# If you want to keep them in sync on every "helm upgrade", set keepAdlistsInSync: true
# adlists:
#   - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

# Whether to update gravity.db to contain only adlists present in the ConfigMap on pod start
# THIS WILL REMOVE ADLISTS WHICH ARE NOT PRESENT IN THE CONFIGMAP!
keepAdlistsInSync: false
```

As you can see, I'm using ingress-nginx controller (outside of the scope for this chart) for the Web UI and I'm also exposing DNS ports on the host where pihole is running.

Here `adlists` is commented out, containing the default value, but you can add more entries there. It will be applied
only on the first startup of the container, unless you also set `keepAdlistsInSync` to `true`. Do note that
enabling the sync will remove any adlists not present in the ConfigMap and will also cause the pod to be recreated if the
`adlists` changes. This is the first step of making the pihole chart support HA.

## Installation

After creating the `values.yaml` file, you can install this chart:

```bash
helm install -n pihole --create-namespace pihole https://github.com/artur-borys/pihole-helm/releases/download/0.1.2/pihole-0.1.2.tgz -f values.yaml
```
