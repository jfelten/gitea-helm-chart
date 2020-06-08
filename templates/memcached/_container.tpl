{{/*
Create helm partial for memcached
*/}}
{{- define "memcached" }}
- name: memcached
  image: {{ .Values.images.memcached }}
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  command:
    - memcached
    - -m {{ .Values.memcached.maxItemMemory  }}
    {{- if .Values.memcached.extendedOptions }}
    - -o
    - {{ .Values.memcached.extendedOptions }}
    {{- end }}
    {{- if .Values.memcached.verbosity }}
    - -{{ .Values.memcached.verbosity }}
    {{- end }}
  ports:
  - name: memcache
    containerPort: 11211
  livenessProbe:
    tcpSocket:
      port: memcache
    initialDelaySeconds: 30
    timeoutSeconds: 5
  readinessProbe:
    tcpSocket:
      port: memcache
    initialDelaySeconds: 5
    timeoutSeconds: 1
  securityContext:
    runAsUser: 1000
  resources:
{{ toYaml .Values.resources.memcached | indent 10 }}
{{- end }}
