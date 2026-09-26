#!/usr/bin/env python3
"""Dağıtım dosyalarını TEK bir servis listesinden üretir.

NEDEN VAR (2026-09-26):
Servis listesi beş ayrı yerde elle tutuluyordu ve birbirinden kopmuştu:
  * docker-compose.yml: 26 servisin 18'inde veritabanı ve JWT ayarı YOKTU
    (servisler açılamazdı); kalan 8'i SÜPER KULLANICIYLA bağlanıyordu, yani
    RLS dağıtımda hiç devrede değildi.
  * k8s/deployments.yaml: yalnızca 2 servis vardı; ingress servisleri
    gateway'i atlayarak ve yanlış yol önekiyle (/v1 ↔ /api/v1) yayınlıyordu.
  * CI: yalnızca 3 servisin imajı üretiliyordu.
  * Dockerfile'lar root kullanıcıyla çalışıyordu.
Bu betik hepsini aynı listeden üretir. `--check` kipi dosyalar listeden
saparsa hata verir; verify-stack.sh bu kipi çalıştırır.

KULLANIM:
  python3 backend/scripts/gen-deploy.py          # dosyaları yaz
  python3 backend/scripts/gen-deploy.py --check  # sapma varsa çıkış kodu 1
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HEADER = "Bu dosya backend/scripts/gen-deploy.py ile ÜRETİLİR — elle düzenlemeyin."

# (dizin, port, dağıtım adı, tür, not)
#   tür: identity → siteeksen_identity rolü; app → siteeksen_app rolü
SERVICES = [
    ("identity",         8081, "identity-service",         "identity", "Kimlik, JWT, sakinler"),
    ("finance",          8082, "finance-service",          "app", "Aidat, ödeme, gecikme tazminatı"),
    ("community",        8083, "community-service",        "app", "Talepler ve duyurular"),
    ("iot",              8084, "iot-service",              "app", "Sayaç ve ısı payı"),
    ("notification",     8085, "notification-service",     "app", "Bildirim merkezi"),
    ("expense",          8086, "expense-service",          "app", "Giderler"),
    ("asset",            8087, "asset-service",            "app", "Demirbaş"),
    ("bulletin",         8089, "bulletin-service",         "app", "İlan panosu"),
    ("contract",         8090, "contract-service",         "app", "Sözleşmeler"),
    ("document",         8091, "document-service",         "app", "Belge arşivi"),
    ("energy_analytics", 8092, "energy-service",           "app", "Enerji analizi"),
    ("esg",              8093, "esg-service",              "app", "Karbon ayak izi"),
    ("inventory",        8094, "inventory-service",        "app", "Stok"),
    ("meeting_wizard",   8095, "meeting-service",          "app", "Yazılmadı — 501 ile governance'a yönlendirir"),
    ("nps",              8096, "nps-service",              "app", "Memnuniyet (NPS)"),
    ("package",          8097, "package-service",          "app", "Kargo"),
    ("parking",          8098, "parking-service",          "app", "Otopark"),
    ("patrol",           8099, "patrol-service",           "app", "Devriye"),
    ("personnel",        8100, "personnel-service",        "app", "Personel (TCKN/IBAN şifreli)"),
    ("reservation",      8101, "reservation-service",      "app", "Ortak alan rezervasyonu"),
    ("settings",         8102, "settings-service",         "app", "Site ayarları"),
    ("smart_collection", 8103, "smart-collection-service", "app", "Tahsilat riski"),
    ("survey",           8104, "survey-service",           "app", "Anket"),
    ("visitor",          8105, "visitor-service",          "app", "Ziyaretçi"),
    ("banking",          8106, "banking-service",          "app", "Yazılmadı — S-07 kararı, 501"),
    ("governance",       8107, "governance-service",       "app", "KMK yönetişim"),
]

# Gateway'in beklediği ortam değişkeni adları (cmd/gateway/main.go)
GATEWAY_ENV = {
    "identity": "IDENTITY_SERVICE_URL", "finance": "FINANCE_SERVICE_URL",
    "community": "COMMUNITY_SERVICE_URL", "iot": "IOT_SERVICE_URL",
    "notification": "NOTIFICATION_SERVICE_URL", "expense": "EXPENSE_SERVICE_URL",
    "asset": "ASSET_SERVICE_URL", "bulletin": "BULLETIN_SERVICE_URL",
    "contract": "CONTRACT_SERVICE_URL", "document": "DOCUMENT_SERVICE_URL",
    "energy_analytics": "ENERGY_SERVICE_URL", "esg": "ESG_SERVICE_URL",
    "inventory": "INVENTORY_SERVICE_URL", "meeting_wizard": "MEETING_SERVICE_URL",
    "nps": "NPS_SERVICE_URL", "package": "PACKAGE_SERVICE_URL",
    "parking": "PARKING_SERVICE_URL", "patrol": "PATROL_SERVICE_URL",
    "personnel": "PERSONNEL_SERVICE_URL", "reservation": "RESERVATION_SERVICE_URL",
    "settings": "SETTINGS_SERVICE_URL", "smart_collection": "SMART_COLLECTION_SERVICE_URL",
    "survey": "SURVEY_SERVICE_URL", "visitor": "VISITOR_SERVICE_URL",
    "banking": "BANKING_SERVICE_URL", "governance": "GOVERNANCE_SERVICE_URL",
}


def req(var, why):
    """Zorunlu compose değişkeni: verilmezse compose AÇILMAZ."""
    return "${%s:?%s}" % (var, why)


# --------------------------------------------------------------------------- Dockerfile
def dockerfile(directory, port, name, build_path):
    extra = ""
    if directory == "document":
        # Yerel depolama kipinde dosyalar bu dizine yazılır (compose'da birime bağlanır).
        extra = "RUN mkdir -p /data/files && chown app:app /data/files\n"
    return f"""# {name} — {HEADER}
#
# Root olmayan kullanıcıyla çalışır; ikili, kaynak kodu içermeyen küçük bir
# imajdadır. Port ve GIN_MODE burada sabitlenir; gizli değerler çalışma
# anında ortam değişkeniyle verilir (imaja GİRMEZ).
FROM golang:1.24-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app {build_path}

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata && addgroup -S app && adduser -S -G app -u 10001 app
{extra}WORKDIR /app
COPY --from=builder /out/app /app/{name}
USER app
ENV PORT={port} GIN_MODE=release
EXPOSE {port}
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \\
  CMD wget -qO- http://127.0.0.1:{port}/health >/dev/null || exit 1
ENTRYPOINT ["/app/{name}"]
"""


# --------------------------------------------------------------------------- compose
def compose():
    out = [f"# {HEADER}",
           "# Servis listesi değişince betiği çalıştırın; verify-stack.sh sapmayı yakalar.",
           "#",
           "# Gizli değerler kök dizindeki .env dosyasından okunur (şablon: .env.example).",
           "# Zorunlu bir değer verilmemişse compose AÇILMAZ: varsayılan bir parola ile",
           "# sessizce ayağa kalkmak, üretimde bilinen parolayla çalışmak demekti.",
           "#",
           "# Veritabanı rolleri (RLS yalnızca süper kullanıcı OLMAYAN rollerde çalışır):",
           "#   siteeksen            → yalnızca migrate (şema sahibi)",
           "#   siteeksen_identity   → yalnızca identity-service",
           "#   siteeksen_app        → diğer bütün servisler",
           "# Rol parolalarını migrate kabı atar (cmd/migrate, APP_/IDENTITY_DB_PASSWORD).",
           "",
           "name: siteeksen",
           "",
           "x-app-env: &app-env",
           "  DB_HOST: postgres",
           '  DB_PORT: "5432"',
           "  DB_NAME: siteeksen",
           "  DB_SSLMODE: disable",
           "  DB_USER: siteeksen_app",
           f"  DB_PASSWORD: {req('APP_DB_PASSWORD', 'APP_DB_PASSWORD gerekli (bkz. .env.example)')}",
           f"  JWT_SECRET: {req('JWT_SECRET', 'JWT_SECRET gerekli (en az 32 karakter)')}",
           "  GIN_MODE: release",
           "",
           "x-after-migrate: &after-migrate",
           "  postgres:",
           "    condition: service_healthy",
           "  migrate:",
           "    condition: service_completed_successfully",
           "",
           "services:",
           "  postgres:",
           "    image: postgres:16-alpine",
           "    # 26 servis × 8 bağlantı = 208 azami; varsayılan 100 yetmez (pkg/database).",
           '    command: ["postgres", "-c", "max_connections=300"]',
           "    environment:",
           "      POSTGRES_DB: siteeksen",
           "      POSTGRES_USER: siteeksen",
           f"      POSTGRES_PASSWORD: {req('DB_PASSWORD', 'DB_PASSWORD gerekli (şema sahibi parolası)')}",
           "    ports:",
           "      # Yalnızca yerel makineye açık; dışarıya yayınlanmaz.",
           '      - "127.0.0.1:${POSTGRES_HOST_PORT:-5432}:5432"',
           "    volumes:",
           "      - postgres_data:/var/lib/postgresql/data",
           "    healthcheck:",
           '      test: ["CMD-SHELL", "pg_isready -U siteeksen -d siteeksen"]',
           "      interval: 5s",
           "      timeout: 5s",
           "      retries: 20",
           "",
           "  # Tek seferlik: migration'ları uygular ve servis rollerine parola atar.",
           "  # Bütün servisler bunun BAŞARIYLA bitmesini bekler.",
           "  migrate:",
           "    build:",
           "      context: ./backend",
           "      dockerfile: cmd/migrate/Dockerfile",
           "    environment:",
           "      DB_HOST: postgres",
           '      DB_PORT: "5432"',
           "      DB_USER: siteeksen",
           f"      DB_PASSWORD: {req('DB_PASSWORD', 'DB_PASSWORD gerekli')}",
           "      DB_NAME: siteeksen",
           "      DB_SSLMODE: disable",
           f"      APP_DB_PASSWORD: {req('APP_DB_PASSWORD', 'APP_DB_PASSWORD gerekli')}",
           f"      IDENTITY_DB_PASSWORD: {req('IDENTITY_DB_PASSWORD', 'IDENTITY_DB_PASSWORD gerekli')}",
           "      # Varsayılan KAPALI: bilinen parolalı demo hesaplar yalnızca açıkça",
           "      # istenirse (SEED_DEMO_DATA=true) yüklenir.",
           "      SEED_DEMO_DATA: ${SEED_DEMO_DATA:-false}",
           "    depends_on:",
           "      postgres:",
           "        condition: service_healthy",
           '    restart: "no"',
           ""]

    for directory, port, name, kind, note in SERVICES:
        out += [f"  # {note}",
                f"  {name}:",
                "    build:",
                "      context: ./backend",
                f"      dockerfile: services/{directory}/Dockerfile",
                "    environment:",
                "      <<: *app-env"]
        if kind == "identity":
            out += ["      DB_USER: siteeksen_identity",
                    f"      DB_PASSWORD: {req('IDENTITY_DB_PASSWORD', 'IDENTITY_DB_PASSWORD gerekli')}"]
        if directory == "personnel":
            out += [f"      PII_ENCRYPTION_KEY: {req('PII_ENCRYPTION_KEY', 'PII_ENCRYPTION_KEY gerekli (32 bayt, base64)')}"]
        if directory == "document":
            out += ["      STORAGE_BACKEND: ${STORAGE_BACKEND:-local}",
                    "      STORAGE_LOCAL_DIR: /data/files",
                    "      S3_ENDPOINT: ${S3_ENDPOINT:-}",
                    "      S3_REGION: ${S3_REGION:-}",
                    "      S3_BUCKET: ${S3_BUCKET:-}",
                    "      S3_ACCESS_KEY_ID: ${S3_ACCESS_KEY_ID:-}",
                    "      S3_SECRET_ACCESS_KEY: ${S3_SECRET_ACCESS_KEY:-}",
                    "      S3_FORCE_PATH_STYLE: ${S3_FORCE_PATH_STYLE:-}"]
        if directory == "document":
            out += ["    volumes:", "      - document_files:/data/files"]
        out += ["    depends_on: *after-migrate",
                "    restart: unless-stopped",
                ""]

    out += ["  # Tek giriş kapısı: kimlik doğrulama, istemci kimlik başlıklarının",
            "  # silinmesi, CORS allowlist, istek kimliği.",
            "  gateway:",
            "    build:",
            "      context: ./backend",
            "      dockerfile: cmd/gateway/Dockerfile",
            "    environment:"]
    for directory, port, name, _, _ in SERVICES:
        out.append(f"      {GATEWAY_ENV[directory]}: http://{name}:{port}")
    out += [f"      JWT_SECRET: {req('JWT_SECRET', 'JWT_SECRET gerekli')}",
            "      CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS:-http://localhost:3001}",
            "      GIN_MODE: release",
            "    ports:",
            '      - "${GATEWAY_HOST_PORT:-8888}:8888"',
            "    depends_on:"]
    for _, _, name, _, _ in SERVICES:
        out.append(f"      - {name}")
    out += ["    restart: unless-stopped",
            "",
            "  admin-panel:",
            "    build:",
            "      context: ./admin",
            "      dockerfile: Dockerfile",
            "      args:",
            "        # Tarayıcıya giden adres DERLEME anında gömülür (Next.js).",
            "        NEXT_PUBLIC_API_URL: ${PUBLIC_API_URL:-http://localhost:8888/api/v1}",
            "    environment:",
            "      # Sunucu tarafı (NextAuth) kabın içinden gateway'e gider.",
            "      API_URL: http://gateway:8888/api/v1",
            "      NEXTAUTH_URL: ${NEXTAUTH_URL:-http://localhost:3001}",
            f"      NEXTAUTH_SECRET: {req('NEXTAUTH_SECRET', 'NEXTAUTH_SECRET gerekli')}",
            "    ports:",
            '      - "3001:3001"',
            "    depends_on:",
            "      - gateway",
            "    restart: unless-stopped",
            "",
            "  # İsteğe bağlı: Kong (bildirimsel yapılandırma kong/kong.yml).",
            "  # Varsayılan giriş kapısı yukarıdaki gateway'dir; Kong yalnızca",
            "  # `docker compose --profile kong up` ile açılır.",
            "  kong:",
            "    image: kong:3.5",
            "    profiles: [kong]",
            "    environment:",
            '      KONG_DATABASE: "off"',
            "      KONG_DECLARATIVE_CONFIG: /kong/kong.yml",
            "      KONG_PROXY_ACCESS_LOG: /dev/stdout",
            "      KONG_PROXY_ERROR_LOG: /dev/stderr",
            "    ports:",
            '      - "8000:8000"',
            "    volumes:",
            "      - ./kong/kong.yml:/kong/kong.yml:ro",
            "    depends_on:",
            "      - gateway",
            "",
            "# Redis, MongoDB ve Kafka KALDIRILDI (2026-09-26): hiçbir servis bunlara",
            "# bağlanmıyor (REDIS_URL / MONGO_URL / KAFKA_BROKERS kodda okunmuyor).",
            "# Çalışmayan altyapıyı ayakta tutmak, var olmayan bir entegrasyonu var",
            "# gibi gösteriyordu.",
            "volumes:",
            "  postgres_data:",
            "  document_files:",
            ""]
    return "\n".join(out)


# --------------------------------------------------------------------------- k8s
def k8s_env_secret(name, secret, key):
    return [f"            - name: {name}",
            "              valueFrom:",
            "                secretKeyRef:",
            f"                  name: {secret}",
            f"                  key: {key}"]


def k8s_env_value(name, value):
    return [f"            - name: {name}", f'              value: "{value}"']


def k8s_deployment(name, image, port, env, replicas=2, notes=""):
    lines = ["---",
             "apiVersion: apps/v1",
             "kind: Deployment",
             "metadata:",
             f"  name: {name}",
             "  labels:",
             f"    app: {name}"]
    if notes:
        lines += ["  annotations:", f'    siteeksen/not: "{notes}"']
    lines += ["spec:",
              f"  replicas: {replicas}",
              "  selector:",
              "    matchLabels:",
              f"      app: {name}",
              "  template:",
              "    metadata:",
              "      labels:",
              f"        app: {name}",
              "    spec:",
              "      securityContext:",
              "        runAsNonRoot: true",
              "        runAsUser: 10001",
              "      containers:",
              f"        - name: {name}",
              f"          image: {image}",
              "          ports:",
              f"            - containerPort: {port}",
              "          securityContext:",
              "            allowPrivilegeEscalation: false",
              "            readOnlyRootFilesystem: true",
              "            capabilities:",
              "              drop: [ALL]",
              "          env:"]
    lines += env
    lines += ["          resources:",
              "            requests:",
              '              memory: "64Mi"',
              '              cpu: "50m"',
              "            limits:",
              '              memory: "256Mi"',
              '              cpu: "500m"',
              "          livenessProbe:",
              "            httpGet:",
              "              path: /health",
              f"              port: {port}",
              "            initialDelaySeconds: 10",
              "            periodSeconds: 30",
              "          readinessProbe:",
              "            httpGet:",
              "              path: /health",
              f"              port: {port}",
              "            initialDelaySeconds: 5",
              "            periodSeconds: 10",
              "---",
              "apiVersion: v1",
              "kind: Service",
              "metadata:",
              f"  name: {name}",
              "spec:",
              "  selector:",
              f"    app: {name}",
              "  ports:",
              "    - protocol: TCP",
              "      port: 80",
              f"      targetPort: {port}",
              "  type: ClusterIP"]
    return lines


SECRETS_DOC = ["#",
               "# Beklenen gizli değerler (kubectl create secret generic ...):",
               "#   db-admin      : host, password           → yalnızca migrate işi (şema sahibi)",
               "#   db-app        : password                 → siteeksen_app (23 servis)",
               "#   db-identity   : password                 → siteeksen_identity (kimlik servisi)",
               "#   app-secrets   : jwt-secret, nextauth-secret, pii-encryption-key",
               "#   storage       : endpoint, region, bucket, access-key-id, secret-access-key",
               "#",
               "# Sıra: önce k8s/migrate-job.yaml tamamlanmalı (şemayı günceller ve rol",
               "# parolalarını atar), sonra bu dosya. CI bu sırayı uygular."]


def k8s_migrate_job():
    img = "ghcr.io/siteeksen"
    out = [f"# {HEADER}"] + SECRETS_DOC + [
           "apiVersion: batch/v1",
           "kind: Job",
           "metadata:",
           "  name: siteeksen-migrate",
           "spec:",
           "  backoffLimit: 1",
           "  ttlSecondsAfterFinished: 86400",
           "  template:",
           "    spec:",
           "      restartPolicy: Never",
           "      securityContext:",
           "        runAsNonRoot: true",
           "        runAsUser: 10001",
           "      containers:",
           "        - name: migrate",
           f"          image: {img}/migrate:latest",
           "          env:"]
    out += k8s_env_secret("DB_HOST", "db-admin", "host")
    out += k8s_env_value("DB_PORT", "5432")
    out += k8s_env_value("DB_USER", "siteeksen")
    out += k8s_env_secret("DB_PASSWORD", "db-admin", "password")
    out += k8s_env_value("DB_NAME", "siteeksen")
    out += k8s_env_value("DB_SSLMODE", "require")
    out += k8s_env_secret("APP_DB_PASSWORD", "db-app", "password")
    out += k8s_env_secret("IDENTITY_DB_PASSWORD", "db-identity", "password")
    out += k8s_env_value("SEED_DEMO_DATA", "false")
    out.append("")
    return "\n".join(out)


def k8s():
    img = "ghcr.io/siteeksen"
    out = [f"# {HEADER}"] + SECRETS_DOC
    for directory, port, name, kind, note in SERVICES:
        env = []
        env += k8s_env_secret("DB_HOST", "db-admin", "host")
        env += k8s_env_value("DB_PORT", "5432")
        env += k8s_env_value("DB_NAME", "siteeksen")
        env += k8s_env_value("DB_SSLMODE", "require")
        if kind == "identity":
            env += k8s_env_value("DB_USER", "siteeksen_identity")
            env += k8s_env_secret("DB_PASSWORD", "db-identity", "password")
        else:
            env += k8s_env_value("DB_USER", "siteeksen_app")
            env += k8s_env_secret("DB_PASSWORD", "db-app", "password")
        env += k8s_env_secret("JWT_SECRET", "app-secrets", "jwt-secret")
        if directory == "personnel":
            env += k8s_env_secret("PII_ENCRYPTION_KEY", "app-secrets", "pii-encryption-key")
        if directory == "document":
            # Kümede yerel disk kalıcı değildir; belge servisi S3 uyumlu depolama
            # ister ve yapılandırma eksikse AÇILMAZ (sessiz dosya kaybı olmasın).
            env += k8s_env_value("STORAGE_BACKEND", "s3")
            env += k8s_env_secret("S3_ENDPOINT", "storage", "endpoint")
            env += k8s_env_secret("S3_REGION", "storage", "region")
            env += k8s_env_secret("S3_BUCKET", "storage", "bucket")
            env += k8s_env_secret("S3_ACCESS_KEY_ID", "storage", "access-key-id")
            env += k8s_env_secret("S3_SECRET_ACCESS_KEY", "storage", "secret-access-key")
        replicas = 1 if directory in ("banking", "meeting_wizard") else 2
        out += k8s_deployment(name, f"{img}/{name}:latest", port, env, replicas, note)

    genv = []
    for directory, port, name, _, _ in SERVICES:
        genv += k8s_env_value(GATEWAY_ENV[directory], f"http://{name}")
    genv += k8s_env_secret("JWT_SECRET", "app-secrets", "jwt-secret")
    genv += k8s_env_value("CORS_ALLOWED_ORIGINS", "https://admin.siteeksen.com")
    out += k8s_deployment("gateway", f"{img}/gateway:latest", 8888, genv, 2,
                          "Tek giriş kapısı — ingress yalnızca buraya yönlendirir")

    aenv = []
    aenv += k8s_env_value("API_URL", "http://gateway/api/v1")
    aenv += k8s_env_value("NEXTAUTH_URL", "https://admin.siteeksen.com")
    aenv += k8s_env_secret("NEXTAUTH_SECRET", "app-secrets", "nextauth-secret")
    admin = k8s_deployment("admin-panel", f"{img}/admin-panel:latest", 3001, aenv, 2)
    # Next.js önbellek dizinine yazar; salt-okur kök dosya sistemi için geçici birim.
    admin = [l.replace("readOnlyRootFilesystem: true", "readOnlyRootFilesystem: false") for l in admin]
    out += admin
    out.append("")
    return "\n".join(out)


def ingress():
    return f"""# {HEADER}
#
# API'nin TEK giriş kapısı gateway'dir: kimlik doğrulama, istemciden gelen
# kimlik başlıklarının silinmesi, CORS ve istek kimliği orada yapılır.
# Servisler doğrudan yayınlanmaz (önceki sürüm identity/finance'i gateway'i
# atlayarak ve yanlış yol önekiyle — /v1 yerine /api/v1 — yayınlıyordu).
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: siteeksen-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "25m"
    nginx.ingress.kubernetes.io/limit-rps: "20"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.siteeksen.com
        - admin.siteeksen.com
      secretName: siteeksen-tls
  rules:
    - host: api.siteeksen.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gateway
                port:
                  number: 80
    - host: admin.siteeksen.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: admin-panel
                port:
                  number: 80
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ssl@siteeksen.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
"""


# --------------------------------------------------------------------------- CI
def ci_matrix():
    lines = ["          # BEGIN gen-deploy: imajlar",
             f"          # {HEADER}"]
    for directory, _, name, _, _ in SERVICES:
        lines += [f"          - name: {name}",
                  "            context: ./backend",
                  f"            dockerfile: services/{directory}/Dockerfile"]
    lines += ["          - name: gateway",
              "            context: ./backend",
              "            dockerfile: cmd/gateway/Dockerfile",
              "          - name: migrate",
              "            context: ./backend",
              "            dockerfile: cmd/migrate/Dockerfile",
              "          - name: admin-panel",
              "            context: ./admin",
              "            dockerfile: Dockerfile",
              "          # END gen-deploy: imajlar"]
    return "\n".join(lines)


def ci_rollout():
    lines = ["          # BEGIN gen-deploy: rollout",
             f"          # {HEADER}"]
    for _, _, name, _, _ in SERVICES:
        lines.append(f"          kubectl rollout status deployment/{name} --timeout=300s")
    lines += ["          kubectl rollout status deployment/gateway --timeout=300s",
              "          kubectl rollout status deployment/admin-panel --timeout=300s",
              "          # END gen-deploy: rollout"]
    return "\n".join(lines)


def replace_block(text, tag, body):
    pat = re.compile(r"[ \t]*# BEGIN gen-deploy: %s\n.*?# END gen-deploy: %s" % (tag, tag), re.S)
    if not pat.search(text):
        raise SystemExit(f"CI dosyasında '{tag}' işaretleri bulunamadı")
    return pat.sub(lambda _: body, text)


# --------------------------------------------------------------------------- main
def targets():
    files = {}
    for directory, port, name, _, _ in SERVICES:
        files[f"backend/services/{directory}/Dockerfile"] = dockerfile(
            directory, port, name, f"./services/{directory}")
    files["backend/cmd/gateway/Dockerfile"] = dockerfile("gateway", 8888, "gateway", "./cmd/gateway")
    files["docker-compose.yml"] = compose()
    files["k8s/migrate-job.yaml"] = k8s_migrate_job()
    files["k8s/deployments.yaml"] = k8s()
    files["k8s/ingress.yaml"] = ingress()
    ci_path = ".github/workflows/ci-cd.yaml"
    ci = open(os.path.join(ROOT, ci_path), encoding="utf-8").read()
    ci = replace_block(ci, "imajlar", ci_matrix())
    ci = replace_block(ci, "rollout", ci_rollout())
    files[ci_path] = ci
    return files


def main():
    check = "--check" in sys.argv
    # Listedeki her servis diskte olmalı; diskteki her servis listede olmalı.
    on_disk = sorted(d for d in os.listdir(os.path.join(ROOT, "backend", "services"))
                     if os.path.isfile(os.path.join(ROOT, "backend", "services", d, "main.go")))
    listed = sorted(s[0] for s in SERVICES)
    if on_disk != listed:
        print("SERVİS LİSTESİ DİSKLE UYUŞMUYOR")
        print("  yalnızca diskte :", sorted(set(on_disk) - set(listed)))
        print("  yalnızca listede:", sorted(set(listed) - set(on_disk)))
        sys.exit(1)

    drift = []
    for rel, content in targets().items():
        path = os.path.join(ROOT, rel)
        current = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if current is not None:
            current = current.replace("\r\n", "\n")
        if current != content:
            drift.append(rel)
            if not check:
                with open(path, "w", encoding="utf-8", newline="\n") as f:
                    f.write(content)
    if check:
        if drift:
            print("Dağıtım dosyaları servis listesinden sapmış:")
            for d in drift:
                print("  -", d)
            print("Düzeltmek için: python3 backend/scripts/gen-deploy.py")
            sys.exit(1)
        print(f"Dağıtım dosyaları güncel ({len(SERVICES)} servis).")
    else:
        print(f"{len(drift)} dosya yazıldı." if drift else "Değişiklik yok.")


if __name__ == "__main__":
    main()
