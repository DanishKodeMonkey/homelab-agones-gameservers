
# Miniature Homelab Game Server Platform

This repository hosts a **homelab-level platform** for running personal dedicated game servers on Kubernetes using **k3s** and **Agones**. It is designed for small-scale private hosting and testing, not production-grade deployments.

Still relative WIP as alot of the features offered by the CRD, Agones, and other ideas can be expanded and improved upon, but at the time of writing the hosting of the starbound server provided works.

Furthermore, this is not intended a ready-to-use copy paste solution, feel free to try and take inspiration from it but don't expect support on this, it's mostly a personal project.

It automates deployment of game servers like Starbound, manages game configuration, mods, and networking, while keeping secrets and large files out of version control.

---

## Prerequisites

1. **Kubernetes cluster** – I use **k3s** for this homelab setup at the time of writing.
2. **Agones** – Game server orchestration framework for Kubernetes.  
   Follow the [Agones Quickstart Guide](https://agones.dev/site/docs/quickstart/) to install Agones in your cluster, e.g:
   ```bash
   kubectl create namespace gameservers
   kubectl apply -f https://raw.githubusercontent.com/googleforgames/agones/release-1.39.0/install/yaml/install.yaml

## Features

- Kubernetes + Agones-based game server orchestration
- Persistent storage for game data via PVCs
- Automated SteamCMD installation and game server setup
- Support for user mods (e.g., `.pak` files)
- Easy local deployment with Helm charts
- Health checks and auto-ready integration with Agones

---

## Repository Structure
```markdown
├── agones/                         # Agones-related configuration
│   ├── rbac/                       # ServiceAccount and RoleBinding for Agones SDK
│   │   ├── agones-sdk-serviceaccount.yaml
│   │   └── agones-sdk-rolebinding.yaml
│   └── test/                        # Example/test GameServers
│       ├── test-gameserver.yaml
│       └── test-gameserver-with-pvc.yaml
├── helm/                            # Helm chart directory for game servers
│   └── gameserver/
│       ├── templates/               # Helm templates
│       │   ├── gameserver.yaml      # Agones GameServer template
│       │   ├── configmap.yaml       # Entrypoint, init scripts, template config
│       │   └── pvc.yaml             # PVC template
│       ├── games/                    # Game-specific assets
│       │   └── starbound/
│       │       ├── data/             # Starbound server files
│       │       │   ├── mods/         # User mod `.pak` files (ignored in Git)
│       │       │   └── starbound_server.config
│       │       └── values.yaml       # Helm values for this server
│       ├── files/                    # Entrypoint and init scripts
│       │   ├── entrypoint.sh
│       │   └── init.sh
│       └── Chart.yaml                # Helm chart metadata
├── .gitignore                        # Excludes mods and secret files
├── .secret.yaml                       # Sensitive Helm values (ignored)
└── README.md                          # This file
```

## How it Works
1. Agones Setup

- Create a ServiceAccount and RoleBinding so your GameServer pods can interact with the Agones SDK.

- Test that your Agones installation works by deploying one of the example GameServers:

```bash
kubectl apply -f agones/test/test-gameserver.yaml
kubectl get gameservers -n gameservers
```
- For persistent data, use the test-gameserver-with-pvc.yaml example, which mounts a PersistentVolumeClaim.


2. Helm Chart Deployment

Before deploying it's important to set up a .secret.yaml file at the root of the project including your steam credentials, this is required for using steamcmd to get any licensed game files.
Remember your steam credentials are personal and should never be committed.
The structure eof your .secret.yaml should be like so
steamcmd:
    user:
    pass:


- The Helm chart deploys your starbound gameserver with:

- Persistent storage for server configs and mods.

- ConfigMap containing startup scripts (entrypoint.sh) and the template configuration.

- Automatic copying of mods from /mods to /assets/user at startup.

- To deploy the server:

```bash
helm upgrade --install starbound ./helm/gameserver \
  -n gameservers \
  -f ./helm/gameserver/games/starbound/values.yaml \
  -f .secret.yaml
```

- Verify the pod and logs:

```bash
kubectl get pods -n gameservers
kubectl logs -f -n gameservers <starbound-pod-name> -c starbound-server
```

3. Mod Management

- Place .pak mod files in helm/gameserver/games/starbound/data/mods/ locally.

- The entrypoint.sh script copies them to /data/assets/user/ on pod startup.

- The .gitignore ensures mods and secrets are not committed.

4. Networking

- Agones dynamically allocates ports to GameServer pods.

- Forward the allocated range (e.g., 7000-8000 TCP/UDP) from your router for external access.

## Notes of potential Improvements

### Steam credentials handling:
Managing Steam login credentials inside Kubernetes posed challenges due to special characters in long complex passwords. I currently store them in a uncommittted .secret.yaml and pass them to the server via environment variables, but parsing and escaping these properly in kubernetes can definately  be improved.

### Mod deployment limitation:
Mod .pak files currently must be manually uploaded to the gameserver pvc (kubectl cp) because the infrastructure to automatically sync mods from local to cluster is not set up. Future improvements could include automating this properly.

Networking & port management:
Testing with dynamic Agones ports showed the importance of avoiding conflicts with router NAT and other services.
Improvements on this fieeld could include proper load balancing through metalLB or otheer solutions to get more tight control of ingress to agones gameservers.

Agones & PVC integration:
Persistent storage is critical for game saves and configuration. The setup with PVCs works, but each new game requires careful volume configuration and setup based on individual game requirements.

Future improvements could include:

Automate mod deployment and syncing.

Integrate agonees fleet scaling features (overkill but fun to try)
# homelab-agones-gameservers
