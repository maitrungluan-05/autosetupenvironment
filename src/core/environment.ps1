# ============================================================================
# DevSetup Core - Environment Refresh Module
# ============================================================================

function Refresh-ProcessEnvironment {
    Log-Debug "Refreshing process environment variables from User and Machine registry scopes..."

    try {
        # Combine System (Machine) and User PATHs
        $machinePath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
        $userPath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

        $combinedPath = "$machinePath;$userPath"
        [Environment]::SetEnvironmentVariable("PATH", $combinedPath, [System.EnvironmentVariableTarget]::Process)
        $env:PATH = $combinedPath

        # Also reload common environment variables like JAVA_HOME if set
        $targetScopes = @([System.EnvironmentVariableTarget]::Machine, [System.EnvironmentVariableTarget]::User)
        foreach ($scope in $targetScopes) {
            $vars = [Environment]::GetEnvironmentVariables($scope)
            foreach ($key in $vars.Keys) {
                if ($key -ne "PATH") {
                    $val = $vars[$key]
                    [Environment]::SetEnvironmentVariable($key, $val, [System.EnvironmentVariableTarget]::Process)
                }
            }
        }

        Log-Debug "Process environment successfully refreshed."
    } catch {
        Log-Warn "Error while refreshing process environment: $_"
    }
}
