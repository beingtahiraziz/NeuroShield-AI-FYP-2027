{{/*
Shared `env:` and `envFrom:` block for backend/daemon/llm-worker pods.

Usage (inside a container spec):
  envFrom:
    {{- include "neuroshield.envFrom" . | nindent 12 }}
  env:
    {{- include "neuroshield.env" . | nindent 12 }}

Both helpers take the root context directly. They pull the generated ConfigMap
and Secret, plus the discrete POSTGRES_* connection parts and REDIS_URL (which
have to be assembled at render time because they embed service DNS + a secret
reference). The app builds and URL-encodes the DSN from POSTGRES_* itself, so
passwords with special characters survive intact (no pre-built DATABASE_URL).

NOTE: secret.yaml is only rendered when secrets.existingSecret is empty AND
secrets.externalSecret.enabled is false. Either way the secretRef below points
at a Secret of the same name (user-supplied, ESO-materialized, or
chart-templated).
*/}}
{{- define "neuroshield.envFrom" -}}
- configMapRef:
    name: {{ include "neuroshield.configmap.fullname" . }}
- secretRef:
    name: {{ include "neuroshield.secret.fullname" . }}
{{- end -}}

{{- define "neuroshield.env" -}}
- name: POSTGRES_HOST
  value: {{ include "neuroshield.postgres.host" . | quote }}
- name: POSTGRES_PORT
  value: {{ include "neuroshield.postgres.port" . | toString | quote }}
- name: POSTGRES_DB
  value: {{ include "neuroshield.postgres.database" . | quote }}
- name: POSTGRES_USER
  value: {{ include "neuroshield.postgres.username" . | quote }}
{{- if .Values.redis.bitnami.enabled }}
{{- if .Values.redis.bitnami.auth.enabled }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "neuroshield.redis.bitnami.passwordSecret" . }}
      key: {{ include "neuroshield.redis.bitnami.passwordSecretKey" . }}
{{- end }}
- name: REDIS_URL
  value: {{ include "neuroshield.redis.url" . | quote }}
{{- else if .Values.redis.enabled }}
- name: REDIS_URL
  value: {{ include "neuroshield.redis.url" . | quote }}
{{- else if .Values.redis.external.url }}
- name: REDIS_URL
  value: {{ .Values.redis.external.url | quote }}
{{- else if .Values.redis.external.existingSecret }}
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.redis.external.existingSecret }}
      key: {{ .Values.redis.external.existingSecretKey | default "REDIS_URL" }}
{{- end }}
{{- end -}}
