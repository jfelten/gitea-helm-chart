{{/*
Create helm partial for gitea server
*/}}
{{- define "firstrun" }}
- name: firstrun
  image: {{ .Values.images.gitea }}
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  env:
  - name: SCRIPT
    value: &script |-
      if [ ! -f /data/gitea/conf/app.ini ]; then
        mkdir -p /data/gitea/conf
        cp /etc/gitea/app.ini /data/gitea/conf/app.ini
        su git -c "mkdir -p /data/git"
        su - git -c "/usr/local/bin/gitea migrate --config /data/gitea/conf/app.ini" | tee /data/migrate.log
      fi
  command: ["/bin/sh",'-c', *script]
  volumeMounts:
  - name: gitea-data
    mountPath: /data
  - name: gitea-config
    mountPath: /etc/gitea
{{- end }}
