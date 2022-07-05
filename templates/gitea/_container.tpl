{{/*
Create helm partial for gitea server
*/}}
{{- define "gitea" }}
- name: gitea
  image: {{ .Values.images.gitea }}
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  {{- if ne .Values.dbType "sqlite3"}}
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
  {{- end }}
  ports:
  - name: ssh
    containerPort: {{ .Values.service.ssh.port  }}
  - name: http
    containerPort: {{ .Values.service.http.port  }}
  livenessProbe:
    tcpSocket:
      port: http
    initialDelaySeconds: 200
    timeoutSeconds: 1
    periodSeconds: 10
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    tcpSocket:
      port: http
    initialDelaySeconds: 5
    periodSeconds: 10
    successThreshold: 1
    failureThreshold: 3
  resources:
{{ toYaml .Values.resources.gitea | indent 10 }}
  volumeMounts:
  - name: gitea-data
    mountPath: /data
  - name: gitea-config
    mountPath: /etc/gitea
{{- end }}
