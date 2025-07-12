{ inputs, lib, config, pkgs, ... }: {
  home.packages = with pkgs; [
    # Cloud security assessment
    prowler

    # Container and infrastructure vulnerability scanning
    trivy

    # Kubernetes security
    kubescape

    # Git secrets scanning
    gitleaks

    # Vulnerability scanner
    nuclei

    # Infrastructure as code security scanner
    checkov
  ];
}
