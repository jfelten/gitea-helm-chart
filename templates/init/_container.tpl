{{/*
Create helm partial for gitea server
*/}}
{{- define "init" }}
- name: init
  image: {{ .Values.images.gitea }}
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  env:
  - name: POSTGRES_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbUser
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbPassword
  - name: SCRIPT
    value: &script |-
      mkdir -p /datatmp/gitea/conf
      if [ ! -f /datatmp/gitea/conf/app.ini ]; then
        sed "s/POSTGRES_PASSWORD/${POSTGRES_PASSWORD}/g; s/POSTGRES_USERNAME/${POSTGRES_USERNAME}/g" < /etc/gitea/app.ini > /datatmp/gitea/conf/app.ini
      fi
  command: ["/bin/sh",'-c', *script]
  volumeMounts:
  - name: gitea-data
    mountPath: /datatmp
  - name: gitea-config
    mountPath: /etc/gitea
{{- end }}
