# WHMCS Docker Image

Image Docker optimisée pour héberger WHMCS avec support PHP 7.4 à 8.3, Apache et IonCube Loader.

## Versions disponibles

- `ghcr.io/OxiWanV2/DockerWHMCS:php7.4` - PHP 7.4
- `ghcr.io/OxiWanV2/DockerWHMCS:php8.0` - PHP 8.0
- `ghcr.io/OxiWanV2/DockerWHMCS:php8.1` - PHP 8.1 (recommandé)
- `ghcr.io/OxiWanV2/DockerWHMCS:php8.2` - PHP 8.2
- `ghcr.io/OxiWanV2/DockerWHMCS:php8.3` - PHP 8.3
- `ghcr.io/OxiWanV2/DockerWHMCS:latest` - PHP 8.1 par défaut

## Variables d'environnement

### Configuration PHP (optionnelles)

| Variable | Défaut | Description |
|----------|--------|-------------|
| `PHP_MEMORY_LIMIT` | `256M` | Limite mémoire PHP |
| `PHP_UPLOAD_MAX_FILESIZE` | `64M` | Taille max upload fichier |
| `PHP_POST_MAX_SIZE` | `64M` | Taille max POST |
| `PHP_MAX_EXECUTION_TIME` | `300` | Temps max exécution (secondes) |
| `PHP_MAX_INPUT_VARS` | `5000` | Nombre max variables input |
| `PHP_TIMEZONE` | `Europe/Paris` | Fuseau horaire PHP |

### Configuration Apache (optionnelle)

| Variable | Défaut | Description |
|----------|--------|-------------|
| `APACHE_PORT` | `8080` | Port d'écoute Apache |

### Configuration Cron WHMCS (optionnelles)

| Variable | Défaut | Description |
|----------|--------|-------------|
| `WHMCS_CRON_ENABLED` | `false` | Activer le cron principal WHMCS |
| `WHMCS_CRON_SCHEDULE` | `*/5 * * * *` | Schedule du cron principal (toutes les 5 min par défaut) |
| `WHMCS_CRON_DAILY_ENABLED` | `false` | Activer le cron journalier WHMCS |
| `WHMCS_CRON_DAILY_HOUR` | `9` | Heure d'exécution du cron journalier (0-23) |
| `WHMCS_CRON_DAILY_MINUTE` | `0` | Minute d'exécution du cron journalier (0-59) |

## Utilisation

### Docker Run basique

```bash
docker run -d \
  --name whmcs \
  -p 8080:8080 \
  -v ./whmcs:/var/www/html \
  ghcr.io/OxiWanV2/DockerWHMCS:php8.1