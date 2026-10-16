# docker-ffw-it

Docker-Compose-Konfiguration für die IT-Infrastruktur der FF Wörnitz (`ffw-it.de`).

Das Repo besteht aus zwei unabhängigen Compose-Stacks:

| Stack                   | Projektname | Inhalt                                                                    |
|-------------------------|-------------|---------------------------------------------------------------------------|
| [`auth/`](auth)         | `auth`      | [authentik](https://goauthentik.io) als Single-Sign-On (`auth.ffw-it.de`) |
| [`services/`](services) | `ffw-it`    | Reverse-Proxy (Traefik) und alle weiteren Dienste                         |

## Architektur

```
                 Internet / VPN
                       │
        :80 :443 :4430 :8883 :8884
                       │
                ┌──────▼──────┐
                │   traefik   │  TLS (Let's Encrypt, Wildcard via Hetzner DNS)
                └──┬───────┬──┘
     Netz backend  │       │  Netz auth_public
                   │       │
   ┌───────────────▼─┐   ┌─▼──────────────────┐
   │ services-Stack  │   │ auth-Stack         │
   │ (db, mqtt, …)   │   │ (authentik server) │
   └─────────────────┘   └────────────────────┘
```

- **Traefik** läuft im `services`-Stack und ist der einzige Container mit öffentlichen Ports. Die Routen werden per
  Docker-Labels an den Containern definiert, statische Routen und Middlewares liegen in [
  `services/traefik/dynamic/`](services/traefik/dynamic).
- **Zertifikate**: Ein Wildcard-Zertifikat für `ffw-it.de`, `*.ffw-it.de`, `*.vpn.ffw-it.de` und `xn--ff-wrnitz-37a.de`
  wird per DNS-Challenge bei Hetzner geholt (siehe [`ssl.yml`](services/traefik/dynamic/ssl.yml)).
- **Netzwerke**:
    - `backend` (`172.20.0.0/24`): internes Netz des `services`-Stacks.
    - `auth_public`: wird vom `auth`-Stack erstellt (Netz `public` im Projekt `auth`). Traefik hängt zusätzlich in
      diesem Netz, um authentik zu erreichen. **Der `auth`-Stack muss deshalb zuerst gestartet werden.**

### Middlewares

| Middleware                       | Wirkung                                                         |
|----------------------------------|-----------------------------------------------------------------|
| `vpn-whitelist@file`             | Zugriff nur aus `10.99.0.0/16` und `10.0.0.0/12` (VPN / intern) |
| `sso-auth@file`                  | Forward-Auth gegen den authentik-Outpost                        |
| `authorized-owntrack-users@file` | Basic-Auth gegen `services/traefik/authorized-owntrack-users`   |

### Entrypoints

| Port   | Entrypoint                  | Zweck                                                     |
|--------|-----------------------------|-----------------------------------------------------------|
| `80`   | `web`                       | Leitet auf HTTPS um                                       |
| `443`  | `websecure`                 | Standard-HTTPS                                            |
| `4430` | `websecureInsecureEncoding` | HTTPS mit erlaubten kodierten `/` und `?` (für Collabora) |
| `8883` | `mqtt-public`               | MQTT über TLS → Mosquitto                                 |
| `8884` | `mqtt-public-ws`            | MQTT über WebSocket + TLS → Mosquitto                     |

## Dienste

| Dienst                  | Datei                                                                           | Adresse                                                      | Zugriff               |
|-------------------------|---------------------------------------------------------------------------------|--------------------------------------------------------------|-----------------------|
| Traefik                 | [`traefik.yaml`](services/compose/traefik.yaml)                                 | `traefik.ffw-it.de` (Dashboard)                              | SSO                   |
| Watchtower              | [`watchtower.yaml`](services/compose/watchtower.yaml)                           | –                                                            | –                     |
| MariaDB                 | [`db.yaml`](services/compose/db.yaml)                                           | intern `db:3306`                                             | nur `backend`         |
| phpMyAdmin              | [`phpmyadmin.yaml`](services/compose/phpmyadmin.yaml)                           | `pma.vpn.ffw-it.de`                                          | VPN + SSO             |
| Mosquitto (MQTT)        | [`mqtt.yaml`](services/compose/mqtt.yaml)                                       | `:8883`, `:8884` (öffentlich), `10.2.254.3:1884` (privat)    | Benutzer/ACL          |
| Node-RED                | [`node-red.yaml`](services/compose/node-red.yaml)                               | `flow.vpn.ffw-it.de`                                         | VPN + SSO             |
| Node-RED Public API     | ″                                                                               | `flow-api.ffw-it.de/api-public/<name>`                       | Basic-Auth            |
| Node-RED OwnTracks      | ″                                                                               | `owntracks-flow.ffw-it.de/api-public/owntracks`              | Basic-Auth            |
| Nextcloud-Divera-Bridge | [`nextcloud_divera_bridge.yaml`](services/compose/nextcloud_divera_bridge.yaml) | `nc-divera-bridge.ffw-it.de`                                 | öffentlich            |
| Collabora Online        | [`collabora.yaml`](services/compose/collabora.yaml)                             | `collabora.ffw-it.de:4430`                                   | für `cloud.ffw-it.de` |
| HedgeDoc                | [`hedgedoc.yaml`](services/compose/hedgedoc.yaml)                               | `pad.ffw-it.de`                                              | SSO                   |
| Vaultwarden             | [`vaultwarden.yaml`](services/compose/vaultwarden.yaml)                         | `vault.ffw-it.de`                                            | eigene Accounts       |
| RustDesk (hbbs/hbbr)    | [`rustdesk.yaml`](services/compose/rustdesk.yaml)                               | `10.2.254.3:21114-21117`                                     | intern                |
| InfluxDB 2              | [`influxdb.yaml`](services/compose/influxdb.yaml)                               | `influxdb.vpn.ffw-it.de`                                     | VPN                   |
| Grafana                 | [`grafana.yaml`](services/compose/grafana.yaml)                                 | `grafana.vpn.ffw-it.de`                                      | VPN + SSO             |
| Kutt (URL-Shortener)    | [`kutt.yaml`](services/compose/kutt.yaml)                                       | `s.ffw-it.de`                                                | SSO                   |
| Web-Public              | [`web-public.yaml`](services/compose/web-public.yaml)                           | `data.ffw-it.de` (Inhalt aus `/opt/www-public` auf dem Host) | öffentlich            |
| Homepage-Redirect       | [`homepage.yml`](services/traefik/dynamic/homepage.yml)                         | `ffw-it.de`, `xn--ff-wrnitz-37a.de` → `ff-woernitz.de`       | öffentlich            |

Die Grafana-Rollen kommen aus den authentik-Gruppen: `Admin` wird Admin, `IT` wird Editor, alle anderen werden Viewer.

## Verzeichnisstruktur

```
auth/
├── docker-compose.yml        # authentik (server, worker, postgres, watchtower)
├── .env.example              # Vorlage für .env
├── .env_authentic            # nicht-geheime authentik-Einstellungen
├── authentik/data/media/     # Logos, Icons, Hintergründe
├── authentik/templates/      # eigene E-Mail-Templates
└── update                    # Update-Skript
services/
├── docker-compose.yml        # include-Liste, Netzwerke
├── compose/<dienst>.yaml     # ein Dienst pro Datei
├── .env.example              # Vorlage für .env
├── env/<dienst>.env.example  # Vorlagen für die Secrets der einzelnen Dienste
├── mqtt-config/              # mosquitto.conf und ACLs je Listener
├── traefik/config.yml        # statische Traefik-Konfiguration
├── traefik/dynamic/          # Middlewares, TLS, statische Routen
├── vaultwarden-overwrite/    # eigene Logos für den Web-Vault
└── update                    # Update-Skript
```

### Aufbau des `services`-Stacks

[`services/docker-compose.yml`](services/docker-compose.yml) bindet die einzelnen Dienste per `include:` ein (Docker
Compose ≥ 2.20):

```yaml
include:
  - path: compose/<dienst>.yaml
    project_directory: .
```

Durch `project_directory: .` werden relative Pfade in den Dienst-Dateien (`./traefik/...`, `env/...`) und die `.env`
weiterhin relativ zu `services/` aufgelöst, nicht relativ zu `services/compose/`.

Named Volumes werden in der Datei des Dienstes definiert, der sie nutzt. Die Netzwerke `backend` und `auth` stehen
zentral in `docker-compose.yml`, weil sie von mehreren Diensten genutzt werden.

## Einrichtung

Voraussetzungen: Docker mit Compose-Plugin ≥ 2.20.

### 1. auth-Stack

```bash
cd auth
cp .env.example .env    # Werte eintragen
docker compose up -d
```

Die authentik-Version wird über `AUTHENTIK_TAG` in `auth/.env` festgelegt.

### 2. services-Stack

```bash
cd services
cp .env.example .env    # HETZNER_API_TOKEN, WATCHTOWER_NOTIFICATION_URL
for f in env/*.env.example; do cp "$f" "${f%.example}"; done   # Werte eintragen
```

Diese Dateien sind nicht im Repo und müssen zusätzlich angelegt werden:

| Datei                                 | Inhalt                                                            |
|---------------------------------------|-------------------------------------------------------------------|
| `traefik/authorized-owntrack-users`   | htpasswd-Datei für die Basic-Auth von Node-RED/OwnTracks          |
| `mqtt-config/listener_public/passwd`  | Mosquitto-Passwortdatei für die öffentlichen Listener (8883/8884) |
| `mqtt-config/listener_private/passwd` | Mosquitto-Passwortdatei für den privaten Listener (1884)          |

Passwörter für Mosquitto anlegen:

```bash
docker compose exec mqtt mosquitto_passwd -c /mosquitto/config/listener_public/passwd <benutzer>
```

Die Datenbanken und Benutzer für HedgeDoc (`hedgedoc`) und Kutt (`kutt`) müssen in MariaDB von Hand angelegt werden, z.
B. über phpMyAdmin.

```bash
docker compose config   # Konfiguration prüfen
docker compose up -d
```

## MQTT

Mosquitto hat vier Listener mit getrennten Benutzern und ACLs (`per_listener_settings true`):

| Port   | Erreichbar über             | Authentifizierung                 |
|--------|-----------------------------|-----------------------------------|
| `8883` | Traefik (TLS), öffentlich   | `listener_public/passwd` + `acl`  |
| `8884` | Traefik (WebSocket + TLS)   | `listener_public/passwd` + `acl`  |
| `1884` | `10.2.254.3:1884`, privat   | `listener_private/passwd` + `acl` |
| `1883` | nur innerhalb von `backend` | anonym (z. B. für Node-RED)       |

Neue MQTT-Benutzer werden in der passenden `passwd` angelegt und bekommen in der zugehörigen `acl` ihre Topics.

## Updates

Beide Stacks haben ein `update`-Skript:

```bash
./services/update
./auth/update
```

Das Skript legt zuerst unter `backups/` eine Sicherung des aktuellen Zustands an (`ps`, `images`, `config`). Danach
zieht es neue Images und fragt, ob die Container neu gestartet werden sollen.

Zusätzlich läuft in beiden Stacks Watchtower:

- **services**: aktualisiert Container automatisch, außer denen mit dem Label
  `com.centurylinklabs.watchtower.monitor-only=true` (traefik, db, mqtt, node-red, nextcloud_divera_bridge). Für diese
  schickt er nur eine Benachrichtigung.
- **auth**: ist grundsätzlich nur im Benachrichtigungs-Modus (`WATCHTOWER_MONITOR_ONLY=true`). authentik wird über
  `AUTHENTIK_TAG` aktualisiert.

## Neuen Dienst hinzufügen

1. `services/compose/<dienst>.yaml` anlegen:

   ```yaml
   volumes:
     <dienst>-data:

   services:
     <dienst>:
       container_name: <dienst>
       image: <image>
       restart: unless-stopped
       networks:
         - backend
       environment:
         TZ: Europe/Berlin
       env_file:
         - env/<dienst>.env
       volumes:
         - <dienst>-data:/data
       labels:
         - "traefik.enable=true"
         - "traefik.http.routers.<dienst>.rule=Host(`<dienst>.ffw-it.de`)"
         - "traefik.http.routers.<dienst>.entrypoints=websecure"
         - "traefik.http.routers.<dienst>.tls=true"
         # nur aus dem VPN und mit SSO:
         # - "traefik.http.routers.<dienst>.middlewares=vpn-whitelist@file,sso-auth@file"
         - "traefik.http.services.<dienst>.loadbalancer.server.port=<port>"
   ```

2. Die Datei in `services/docker-compose.yml` unter `include:` eintragen (mit `project_directory: .`).
3. Für Secrets eine Vorlage `env/<dienst>.env.example` anlegen. Die echte `env/<dienst>.env` wird durch `.gitignore`
   nicht eingecheckt.
4. Bei SSO in authentik eine Application und einen Provider anlegen.
5. Mit `docker compose config` prüfen und dann mit `docker compose up -d` starten.

Subdomains unter `*.ffw-it.de` und `*.vpn.ffw-it.de` deckt das Wildcard-Zertifikat schon ab. Andere Domains müssen in [
`ssl.yml`](services/traefik/dynamic/ssl.yml) ergänzt werden.
