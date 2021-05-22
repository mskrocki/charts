{{/* Define the secrets */}}
{{- define "bitwarden.secrets" -}}

{{- $adminToken := "" }}
{{- if eq .Values.bitwardenrs.admin.enabled true }}
{{- $adminToken = .Values.bitwardenrs.admin.token | default (randAlphaNum 48) | b64enc | quote }}
{{- end -}}

{{- $smtpUser := "" }}
{{- if and (eq .Values.bitwardenrs.smtp.enabled true ) (.Values.bitwardenrs.smtp.user) }}
{{- $smtpUser = .Values.bitwardenrs.smtp.user | b64enc | quote }}
{{- end -}}

{{- $yubicoClientId := "" }}
{{- if eq .Values.bitwardenrs.yubico.enabled true }}
{{- $yubicoClientId = required "Yubico Client ID required" .Values.bitwardenrs.yubico.clientId | toString | b64enc | quote }}
{{- end -}}
---

apiVersion: v1
kind: Secret
metadata:
  name: bitwardensecret
data:
  {{- if ne $adminToken "" }}
  ADMIN_TOKEN: {{ $adminToken }}
  {{- end }}
  {{- if ne $smtpUser "" }}
  SMTP_USERNAME: {{ $smtpUser }}
  SMTP_PASSWORD: {{ required "Must specify SMTP password" .Values.bitwardenrs.smtp.password | b64enc | quote }}
  {{- end }}
  {{- if ne $yubicoClientId "" }}
  YUBICO_CLIENT_ID: {{ $yubicoClientId }}
  YUBICO_SECRET_KEY: {{ required "Yubico Secret Key required" .Values.bitwardenrs.yubico.secretKey | b64enc | quote }}
  {{- end }}

---

apiVersion: v1
kind: Secret
metadata:
  labels:
    {{- include "common.labels" . | nindent 4 }}
  name: dbcreds
{{- $previous := lookup "v1" "Secret" .Release.Namespace "dbcreds" }}
{{- $dbPass := "" }}
data:
{{- if $previous }}
  {{- $dbPass = ( index $previous.data "postgresql-password" ) | b64dec  }}
  postgresql-password: {{ ( index $previous.data "postgresql-password" ) }}
  postgresql-postgres-password: {{ ( index $previous.data "postgresql-postgres-password" ) }}
{{- else }}
  {{- $dbPass = randAlphaNum 50 }}
  postgresql-password: {{ $dbPass | b64enc | quote }}
  postgresql-postgres-password: {{ randAlphaNum 50 | b64enc | quote }}
{{- end }}
  url: {{ ( printf "%v%v:%v@%v-%v:%v/%v" "postgresql://" .Values.postgresql.postgresqlUsername $dbPass .Release.Name "postgresql" "5432" .Values.postgresql.postgresqlDatabase  ) | b64enc | quote }}
type: Opaque
{{- end -}}
