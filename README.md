# Pihole Helm chart

![Build Status](https://github.com/artur-borys/pihole-helm/actions/workflows/build.yml/badge.svg)

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

# It's possible to run multiple replicas,
# but the ingress must be configured for sticky sessions
replicas: 1

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

pvc:
  # persistence can be disabled if you don't care about query logs and stats
  enabled: true
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
# Below you can find commented out default value of adlists
# adlists:
#   - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts

# Whether to update gravity.db to contain only adlists present in the ConfigMap on pod start
# THIS WILL REMOVE ADLISTS WHICH ARE NOT PRESENT IN THE CONFIGMAP!
keepAdlistsInSync: false

# Custom environment variables. See https://github.com/pi-hole/docker-pi-hole#environment-variables
# ALL MUST BE OF TYPE STRING - wrap them in quotes to be safe
# Below you can find example variables - they are NOT set by default
environment:
  {}
  # DNSSEC: "true"
  # DNS_BOGUS_PRIV: "true"
  # WEBTHEME: "default-darker"
  # FTLCONF_RATE_LIMIT: "2000/60"
  # DNSMASQ_LISTENING: all

# Whether to restart the pod after Helm upgrade changing the environment ConfigMap
restartOnEnvironmentChange: false
```

As you can see, I'm using ingress-nginx controller (outside of the scope for this chart) for the Web UI and I'm also exposing DNS ports on the host where pihole is running.

Here `adlists` is commented out, containing the default value, but you can add more entries there. It will be applied
only on the first startup of the container, unless you also set `keepAdlistsInSync` to `true`. Do note that
enabling the sync will remove any adlists not present in the ConfigMap and will also cause the pod to be recreated if the
`adlists` changes. This is the first step of making the pihole chart support HA.

In 0.1.3 `environment` was added, allowing to set additional environment variables related to pihole. It's also possible to make `helm upgrade` trigger a restart
when the upgrade changes the environment variables.

## Installation

After creating the `values.yaml` file, you can install this chart:

```bash
helm install -n pihole --create-namespace pihole https://github.com/artur-borys/pihole-helm/releases/download/0.1.6/pihole-0.1.6.tgz -f values.yaml
```

## Modifying configuration

Pihole is somewhat reconfigurable and this Helm charts makes it possible to do so

### Updating adlists

If you're like me, and you prefer to use any GUIs as little as possible, you might find it useful that this chart supports controlling adlists via Helm values.

There are two parameters related to it:

- `adlists` - which is a list of adlists
- `keepAdlistsInSync` - a boolean value which controls whether the adlists from values are reflected in Gravity database. It basically means, that the resulting ConfigMap, created from Helm values, is the source of adlists. When you add a list via GUI and you won't have it in `adlists`, it will be deleted on the next restart of the pod. Additionaly, when this is set to `true`, Helm will trigger a pod restart whenever `adlists` has changed.

By default, `adlists` is used to populate Gravity only on the first run. Unless `keepAdlistsInSync` is set to `true`, Gravity won't be modified by this Helm chart.

### Environment variables

Pihole docker image can be configured via environment variables (https://github.com/pi-hole/docker-pi-hole#environment-variables).

This Helm chart exposes `environment` variable, which is a dict of environment variables. All values must be string, so it's worth quoting them to make sure they will be treated as strings.

By default, the pod won't be automatically restarted upon `environment` change, but this can be turned on by setting `restartOnEnvironmentChange` to `true`.

### Running multiple replicas

It's possible to run multiple instances of pihole, however they are not synchronised, which means that the cache, query logs and stats and other things will differ between instances.
There's also a caveat that the web GUI won't work without an ingress, and the ingress has to support sticky sessions.

Below you can find example configuration for ingress-nginx:

```yaml
# Configure ingress-nginx for sticky sessions
ingress:
  className: nginx
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    cert-manager.io/private-key-algorithm: ECDSA
    cert-manager.io/private-key-size: "384"
    nginx.ingress.kubernetes.io/affinity: cookie
    nginx.ingress.kubernetes.io/affinity-mode: persistent
    nginx.ingress.kubernetes.io/session-cookie-secure: "true"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "3600"
  hosts:
    - host: "pihole.example.com"
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - pihole.example.com
      secretName: ingress-tls

replicas: 3

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

# Since stats, query logs etc. will differ on all instances, it doesn't make much sense to persist anything
pvc:
  enabled: false

# DNS service config when using MetalLB
# When using NGINX Ingress, you can also expose UDP/TCP ports: https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/
dnsService:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/loadBalancerIPs: "10.100.0.100"

adlists:
  - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
  - https://raw.githubusercontent.com/FiltersHeroes/KADhosts/master/KADhosts.txt
  - https://raw.githubusercontent.com/MajkiIT/polish-ads-filter/master/polish-pihole-filters/hostfile.txt
  - https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-hosts-online.txt
  - https://hole.cert.pl/domains/v2/domains_hosts.txt

# Custom environment variables. See https://github.com/pi-hole/docker-pi-hole#environment-variables
environment:
  DNSSEC: "true"
  DNS_BOGUS_PRIV: "true"
  WEBTHEME: "default-darker"
  FTLCONF_RATE_LIMIT: 3000/60
  DNSMASQ_LISTENING: all

# Whether to restart the pod after Helm upgrade changing the environment ConfigMap
restartOnEnvironmentChange: true
```

# Known issues

## Not responding on DNS UDP port

There's a "feature" in Kubernetes related to `hostPort` which sometimes makes it impossible to expose the same port number with both `TCP` and `UDP` protocols.
This can happen if you first set only `dnsTcpOnHost.enabled` to `true`, but not `dnsUdpOnHost.enabled`. If you then set the UDP to be exposed on host - it probably won't work.

The solution is to uninstall the Helm release and reinstall it fresh. The PVC's should be left untouched, so you won't loose any configuration or query logs, but it's always a good idea to use the Teleporter feature of Pihole to back up.

You can read more about this Kubernetes "feature" here: https://ben-lab.github.io/kubernetes-UDP-TCP-bug-same-port/
