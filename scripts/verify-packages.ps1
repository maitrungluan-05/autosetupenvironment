$ids = @(
    'Microsoft.OpenJDK.21',
    'Apache.Maven',
    'Gradle.Gradle',
    'JetBrains.IntelliJIDEA.Community',
    'Python.Python.3.13',
    'Python.Python.3',
    'OpenJS.NodeJS.LTS',
    'Microsoft.VisualStudioCode',
    'Git.Git',
    'GitHub.cli',
    'Kitware.CMake',
    'Ninja-build.Ninja',
    'LLVM.LLVM',
    'Microsoft.VisualStudio.2022.BuildTools',
    'Golang.Go',
    'Rustlang.Rustup',
    'Docker.DockerDesktop',
    'Kubernetes.kubectl',
    'Helm.Helm',
    'HashiCorp.Terraform',
    'Amazon.AWSCLI',
    'Microsoft.AzureCLI',
    'pnpm.pnpm',
    'Yarn.Yarn'
)

foreach ($id in $ids) {
    $null = winget show --id $id --exact 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK]   $id" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $id" -ForegroundColor Red
    }
}
