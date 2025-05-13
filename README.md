# Helm Charts

Welcome to the Helm Charts repository for **EdgeCDN-X**. This repository contains a collection of Helm charts to help you deploy and manage applications on Kubernetes.

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

Helm is a package manager for Kubernetes that simplifies the deployment and management of applications. This repository provides pre-configured Helm charts for various applications and services.

## Usage

To use a chart from this repository, follow these steps:

1. Add the repository to Helm:
    ```bash
    helm repo add tbotech https://example.com/helm-charts
    helm repo update
    ```

2. Install a chart:
    ```bash
    helm install my-release tbotech/<chart-name>
    ```

3. Customize the installation by providing your own `values.yaml` file:
    ```bash
    helm install my-release tbotech/<chart-name> -f values.yaml
    ```

## Contributing

We welcome contributions! To contribute:

1. Fork the repository.
2. Create a new branch for your changes.
3. Submit a pull request with a detailed description of your changes.

## License

This repository is licensed under the [MIT License](LICENSE).

---

For more information, visit the [Helm documentation](https://helm.sh/docs/).