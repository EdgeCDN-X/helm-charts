{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "coredns.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "coredns.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "coredns.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
{{- if .Values.isClusterService }}
k8s-app: {{ template "coredns.k8sapplabel" . }}
kubernetes.io/cluster-service: "true"
kubernetes.io/name: "CoreDNS"
{{- end }}
app.kubernetes.io/name: {{ template "coredns.name" . }}
{{- end -}}

{{/*
Common labels with autoscaler
*/}}
{{- define "coredns.labels.autoscaler" -}}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
{{- if .Values.isClusterService }}
k8s-app: {{ template "coredns.k8sapplabel" . }}-autoscaler
kubernetes.io/cluster-service: "true"
kubernetes.io/name: "CoreDNS"
{{- end }}
app.kubernetes.io/name: {{ template "coredns.name" . }}-autoscaler
{{- end -}}

{{/*
Extra labels for autoscaler resources.
Inherits top-level customLabels when autoscaler.inheritCustomLabels is true,
then applies autoscaler.customLabels (overrides on key conflicts).
*/}}
{{- define "coredns.autoscaler.extraLabels" -}}
{{- $labels := dict -}}
{{- if .Values.autoscaler.inheritCustomLabels -}}
{{- range $k, $v := (default dict .Values.customLabels) -}}
{{- $_ := set $labels $k $v -}}
{{- end -}}
{{- end -}}
{{- range $k, $v := (default dict .Values.autoscaler.customLabels) -}}
{{- $_ := set $labels $k $v -}}
{{- end -}}
{{- if $labels -}}
{{- toYaml $labels -}}
{{- end -}}
{{- end -}}

{{/*
Allow k8s-app label to be overridden
*/}}

{{/*
Allow k8s-app label to be overridden
*/}}
{{- define "coredns.k8sapplabel" -}}
{{- default .Chart.Name .Values.k8sAppLabelOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate the list of ports automatically from the server definitions
*/}}

{{/*
Generate the list of port automatically from the server definitions
*/}}
{{- define "coredns.servicePortsV2" -}}
{{- $ports := dict -}}

{{- range .Values.servers }}
{{- range .zones }}
    {{- $port := toString .port -}}
    {{- if not (hasKey $ports $port) -}}
        {{- $ports := set $ports $port (dict "istcp" false "isudp" false) -}}
    {{- end -}}
    {{- $innerdict := index $ports $port -}}
    {{- if has (default "" .scheme) (list "dns://" "") -}}
        {{- if eq (default false .use_tcp) true }}
            {{- $innerdict := set $innerdict "istcp" true -}}
        {{- else }}
            {{- $innerdict := set $innerdict "isudp" true -}}
        {{- end }}
    {{- end -}}
    {{- if has (default "" .scheme) (list "tls://" "grpc://" "https://") -}}
        {{- $innerdict := set $innerdict "istcp" true -}}
    {{- end -}}
    {{- if .nodePort -}}
        {{- $innerdict := set $innerdict "nodePort" .nodePort -}}
    {{- end -}}
    {{- $ports := set $ports $port $innerdict -}}
{{- end }}
{{- end }}
{{/* Write out the ports according to the info collected above */}}
{{- range $port, $innerdict := $ports -}}
    {{- $portList := list -}}
    {{- if index $innerdict "isudp" -}}
        {{- $portList = append $portList (dict "port" ($port | int) "protocol" "UDP" "name" (printf "udp-%s" $port)) -}}
    {{- end -}}
    {{- if index $innerdict "istcp" -}}
        {{- $portList = append $portList (dict "port" ($port | int) "protocol" "TCP" "name" (printf "tcp-%s" $port)) -}}
    {{- end -}}
    {{- range $portDict := $portList -}}
        {{- if index $innerdict "nodePort" -}}
            {{- $portDict := set $portDict "nodePort" (get $innerdict "nodePort" | int) -}}
        {{- end -}}
        {{- printf "- %s\n" (toJson $portDict) -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate the list of ports automatically from the server definition
*/}}
{{- define "coredns.containerPortsV2" -}}
{{- $ports := dict -}}

{{- range .Values.servers }}

{{- range .zones }}
    {{- $port := toString .port -}}
    {{- if not (hasKey $ports $port) -}}
        {{- $ports := set $ports $port (dict "istcp" false "isudp" false ) -}}
    {{- end -}}

    {{- $innerdict := index $ports $port -}}
    {{- if has (default "" .scheme) (list "dns://" "") -}}
        {{- if eq (default false .use_tcp) true }}
            {{- $innerdict := set $innerdict "istcp" true -}}
        {{- else }}
            {{- $innerdict := set $innerdict "isudp" true -}}
        {{- end }}
    {{- end -}}
    {{- if has (default "" .scheme) (list "tls://" "grpc://" "https://") -}}
        {{- $innerdict := set $innerdict "istcp" true -}}
    {{- end -}}

    {{- if .hostPort -}}
        {{- $innerdict := set $innerdict "hostPort" .hostPort -}}
    {{- end -}}
    {{- $ports := set $ports $port $innerdict -}}
{{- end -}}

{{- range .plugins -}}
    {{- if eq .name "prometheus" -}}
        {{- $prometheus_addr := toString .parameters -}}
        {{- $prometheus_addr_list := regexSplit ":" $prometheus_addr -1 -}}
        {{- $prometheus_port := last $prometheus_addr_list }}
        {{- $ports := set $ports $prometheus_port (dict "istcp" true "isudp" false) -}}
    {{- end -}}
{{- end -}}

{{/* Write out the ports according to the info collected above */}}
{{- range $port, $innerdict := $ports -}}
    {{- $portList := list -}}
    {{- if index $innerdict "isudp" -}}
        {{- $portList = append $portList (dict "containerPort" ($port | int) "protocol" "UDP" "name" (printf "udp-%s" $port)) -}}
    {{- end -}}
    {{- if index $innerdict "istcp" -}}
        {{- $portList = append $portList (dict "containerPort" ($port | int) "protocol" "TCP" "name" (printf "tcp-%s" $port)) -}}
    {{- end -}}

    {{- range $portDict := $portList -}}
        {{- if index $innerdict "hostPort" -}}
            {{- $portDict := set $portDict "hostPort" (get $innerdict "hostPort" | int) -}}
        {{- end -}}

        {{- printf "- %s\n" (toJson $portDict) -}}
    {{- end -}}
{{- end -}}

{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "coredns.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "coredns.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "coredns.clusterRoleName" -}}
{{- if and .Values.clusterRole .Values.clusterRole.nameOverride -}}
    {{ .Values.clusterRole.nameOverride }}
{{- else -}}
    {{ template "coredns.fullname" . }}
{{- end -}}
{{- end -}}
