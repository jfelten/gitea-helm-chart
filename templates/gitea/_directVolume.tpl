{{- define "gitea_volume" }}
{{ .Values.persistence.directGiteaVolumeMount }}
{{- end }}
