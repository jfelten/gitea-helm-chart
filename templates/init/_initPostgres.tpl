{{/*
Create helm partial for gitea server
*/}}
{{- define "initPostgres" }}
{{ if (.Values.useInPodPostgres) }}
- name: "create-subpath"
  image: busybox:1.32.0
  imagePullPolicy: IfNotPresent
  command: ["/bin/sh"]
  args: ["-c","mkdir -p {{ .Values.inPodPostgres.dataMountPath  }}/{{ .Values.inPodPostgres.subPath  }};"]
  volumeMounts:
  - name: postgres-data
    mountPath: {{ .Values.inPodPostgres.dataMountPath }}
- name: "change-permission-of-directory"
  image: busybox:1.32.0
  imagePullPolicy: IfNotPresent
  command: ["/bin/sh"]
  args: ["-c", "chown -R 999:999 {{ .Values.inPodPostgres.dataMountPath }}"]
  volumeMounts:
  - name: postgres-data
    mountPath: {{ .Values.inPodPostgres.dataMountPath }}
    subPath: {{ .Values.inPodPostgres.subPath  }}
{{- end }}
{{ if and (not .Values.useInPodPostgres) (.Values.externalDB) (eq "postgres" .Values.dbType ) }}
- name: init-postgres
  image: "{{ .Values.images.postgres }}"
  imagePullPolicy: {{ .Values.images.imagePullPolicy }}
  env:
  - name: PGHOST
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbHost
  - name: PGPORT
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbPort
  - name: DATABASE
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbDatabase
  - name: PGUSER
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbUser
  - name: PGPASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "db.fullname" . }}
        key: dbPassword
  - name: POSTGRES_INIT_SCRIPT
    value: &POSTGRES_INIT_SCRIPT |-
      echo "checking postresql for existence of db: $DATABASE";
      DB_EXIST=$(psql -lqt -w | cut -d \| -f 1 | grep ${DATABASE} | sed 's: ::g');
      echo "db exists ${DB_EXIST}:${DATABASE}";
      if [ "${DB_EXIST}" != "${DATABASE}" ]; then
        psql -c "CREATE DATABASE ${DATABASE}";
      else
        echo "existing database detected."
      fi

  command: ["/bin/bash"]
  args: ["-c", *POSTGRES_INIT_SCRIPT]
{{- end }}
{{- end }}
