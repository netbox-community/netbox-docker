{{- define "netbox.common" -}}
{{- $postgresql := (dict "Release" (dict "Name" .Release.Name) "Chart" (dict "Name" "postgresql") "Values" (index .Values.postgresql)) }}
{{- $netboxEnv := include (print $.Template.BasePath "/netbox-env.yaml") . }}
{{- $netboxSecretEnv := include (print $.Template.BasePath "/netbox-secret-env.yaml") . }}
{{- $nginxConfig := include (print $.Template.BasePath "/nginx-config.yaml") . }}
selector:
  matchLabels:
    app.kubernetes.io/name: {{ include "netbox.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
template:
  metadata:
    labels:
      app.kubernetes.io/name: {{ include "netbox.name" . }}
      app.kubernetes.io/instance: {{ .Release.Name }}
    annotations:
      checksum/config: {{ print "%s%s%s" $netboxEnv $netboxSecretEnv $nginxConfig | sha256sum }}
  spec:
    containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        resources:
          {{- toYaml .Values.resources | indent 12 }}
        envFrom:
        - configMapRef:
            name: "{{ include "netbox.fullname" . }}-env"
        - secretRef:
            name: "{{ include "netbox.fullname" . }}-env"
{{- if or (or .Values.postgresql.enabled .Values.redis.enabled) .Values.redis.existingSecret }}
        env:
{{- if .Values.postgresql.enabled }}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: "{{ include "postgresql.fullname" $postgresql }}"
              key: "postgresql-password"
{{- end }}
{{- if or .Values.redis.enabled .Values.redis.existingSecret }}
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
{{- if .Values.redis.existingSecret }}
              name: {{ .Values.redis.existingSecret | quote}}
{{- else }}
              name: {{ include "redis.child.fullname" . | trim | quote }}
{{- end }}
              key: 'redis-password'
{{- end }}
{{- end }}
        volumeMounts:
        - name: netbox-static-files
          mountPath: /opt/netbox/netbox/static/
        - name: netbox-media-files
          mountPath: /etc/netbox/media
        {{- if .Values.initializers }}
        - name: netbox-initializers
          mountPath: /opt/netbox/initializers/
        {{- end }}
        {{- range $mount := .Values.extraVolumeMounts }}
        - {{ $mount | toYaml | indent 10 | trim }}
        {{- end }}
      - name: nginx
        image: "{{ .Values.nginxImage.repository }}:{{ .Values.nginxImage.tag }}"
        imagePullPolicy: {{ .Values.nginxImage.pullPolicy }}
        command: ["nginx"]
        args: ["-c", "/etc/netbox-nginx/nginx.conf", "-g", "daemon off;"]
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        {{- with .Values.livenessProbe }}
        livenessProbe:
          {{ . | toYaml | indent 10 | trim }}
        {{- end }}
        {{- with .Values.readinessProbe }}
        readinessProbe:
          {{ . | toYaml | indent 10 | trim }}
        {{- end }}
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/netbox-nginx/
        - name: netbox-static-files
          mountPath: /opt/netbox/netbox/static
      {{- range $container := .Values.extraContainers }}
      - {{ $container | toYaml | indent 8 | trim }}
      {{- end }}
    {{- if .Values.extraInitContainers }}
    initContainers:
    {{ toYaml .Values.extraInitContainers | nindent 4}}
    {{- end }}
    restartPolicy: {{ .Values.restartPolicy }}
    {{- with .Values.nodeSelector }}
    nodeSelector:
    {{- toYaml . | indent 4  }}
    {{- end }}
    {{- with .Values.affinity }}
    affinity:
    {{- toYaml . | indent 4 }}
    {{- end }}
    {{- with .Values.tolerations }}
    tolerations:
    {{- toYaml . | indent 4 }}
    {{- end }}
    volumes:
    {{- range $volume := .Values.extraVolumes }}
    - {{ $volume | toYaml | indent 6 | trim }}
    {{- end }}
    {{- if .Values.initializers }}
    - name: netbox-initializers
      configMap:
        name: {{ include "netbox.fullname" . }}-initializers
    {{- end }}
    - name: nginx-config
      configMap:
        name: {{ include "netbox.fullname" . }}-nginx
    - name: netbox-config-file
      configMap:
        name: {{ include "netbox.fullname" . }}-nginx
    - name: netbox-static-files
      emptyDir: {}
{{- if not .Values.persistence.enabled }}
    - name: netbox-media-files
      emptyDir: {}
{{- end }}
{{- end -}}
