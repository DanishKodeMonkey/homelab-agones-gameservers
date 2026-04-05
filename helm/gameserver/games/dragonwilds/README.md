## Dragonwilds

Before deploying, keep non-secret server identity in `values.yaml` and place the sensitive values in `.secret.yaml`.

Set in `values.yaml`:

- `dragonwilds.serverName`
- `dragonwilds.defaultWorldName`

Set in `.secret.yaml`:

- `dragonwilds.ownerId`
- `dragonwilds.adminPassword`
- `dragonwilds.worldPassword` if you want a password-protected server

Example `.secret.yaml`:

```yaml
dragonwilds:
  ownerId: "000206eb52554eb1b1937b7cac909060"
  adminPassword: "change-me"
  worldPassword: ""
```

Deploy with:

```bash
helm upgrade --install dragonwilds ./helm/gameserver \
  -n gameservers \
  -f ./helm/gameserver/games/dragonwilds/values.yaml \
  -f .secret.yaml
```

Quick validation:

```bash
kubectl get gameservers -n gameservers
kubectl get pods -n gameservers
kubectl logs -n gameservers dragonwilds-server -c dragonwilds-server --tail=100
kubectl logs -n gameservers dragonwilds-server -c dragonwilds-server-steamcmd --tail=100
```

Notes:

- This overlay installs the dedicated server anonymously with Steam app id `4019830`.
- The live dedicated server config is written to `/data/RSDragonwilds/Saved/Config/LinuxServer/DedicatedServer.ini`.
- The config format the game actually uses is the Unreal section `[/Script/Dominion.DedicatedServerSettings]`.
- `ownerId`, `adminPassword`, and `worldPassword` can be supplied through `.secret.yaml` so they do not need to live in the checked-in values file.
- The PVC keeps the game files, config, and world data under `/data`.
- The startup command is set to `/data/RSDragonwildsServer.sh -log`.
- Agones exposes a dynamic host UDP port. Check `kubectl get gameserver dragonwilds-server -n gameservers` and use the assigned host port, not container port `7777`, for client connections.
