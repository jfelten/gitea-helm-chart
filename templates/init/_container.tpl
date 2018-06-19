{{/*
Create helm partial for gitea server
*/}}
{{- define "init" }}
- name: init
  image: {{ .Values.images.gitea }}
  imagePullPolicy: {{ .Values.images.pullPolicy }}
  env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "postgresql.fullname" . }}
        key: postgres-password
  - name: SCRIPT
    value: &script |- 
      mkdir -p /datatmp/gitea/conf
      cp -f /etc/gitea/app.ini /datatmp/gitea/conf/app.ini
      sed -i "s/POSTGRES_PASSWORD/${POSTGRES_PASSWORD}/g" /datatmp/gitea/conf/app.ini
  command: ["/bin/sh",'-c', *script]
  volumeMounts:
  - name: gitea-data
    mountPath: /datatmp
  - name: gitea-config
    mountPath: /etc/gitea
{{- end }}
