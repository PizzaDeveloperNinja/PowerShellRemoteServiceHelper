Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to check if the script is running with administrative privileges
function Check-AdminPrivileges {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to load configuration
function Load-ConfigFile {
    $configFilePath = ".\config.txt"

    if (-Not (Test-Path $configFilePath)) {
        Write-Host "Config file not found."
        exit
    }

    $config = @()
    $currentServer = $null

    foreach ($line in Get-Content $configFilePath) {
        $line = $line.Trim()

        # Skip comments and empty lines
        if ($line -eq "" -or $line.StartsWith("#")) {
            continue
        }

        if ($line -like "server=*") {
            $currentServer = $line -replace "server=", ""
        } elseif ($line -like "services=*") {
            $services = $line -replace "services=", "" -split ",\s*"
            if ($currentServer -and $services.Count -gt 0) {
                $config += [pscustomobject]@{
                    Server = $currentServer
                    Services = $services
                }
                Write-Host "Added services for server ${currentServer}: $(${services -join ', '})"
            }
        }
    }

    if ($config.Count -eq 0) {
        Write-Host "No valid configuration found."
        exit
    }

    return $config
}
# Function to get service status
function Get-ServiceStatus {
    param (
        [string]$Server,
        [string[]]$ServiceNames
    )
    $serviceStatuses = @()
    foreach ($serviceName in $ServiceNames) {
        try {
            $service = Get-WmiObject -Class Win32_Service -ComputerName $Server -Filter "Name='$serviceName'" -ErrorAction Stop
            $serviceStatuses += [pscustomobject]@{
                Server = $Server
                Name = $serviceName
                Status = $service.State
                StartupType = $service.StartMode
                LastChecked = (Get-Date).ToString()
            }
        } catch {
            Write-Host "Service '$serviceName' on server '$Server' not found."
            $serviceStatuses += [pscustomobject]@{
                Server = $Server
                Name = $serviceName
                Status = "Not Found"
                StartupType = "N/A"
                LastChecked = (Get-Date).ToString()
            }
        }
    }
    return $serviceStatuses
}

# Function to update the debug console
function Update-DebugConsole {
    param (
        [string]$message
    )
    if ($form.InvokeRequired) {
        $form.Invoke([action]{ Update-DebugConsole -message $message })
    } else {
        $debugConsole.AppendText("$message`r`n")
        $debugConsole.SelectionStart = $debugConsole.Text.Length
        $debugConsole.ScrollToCaret()
    }
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Service Helper"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"

# Create a DataGridView to display services
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 10)
$dataGridView.Size = New-Object System.Drawing.Size(660, 350)
$dataGridView.AutoSizeColumnsMode = "Fill"
$dataGridView.AllowUserToAddRows = $false  # Prevent user from adding new rows

# Add columns
$checkBoxColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$checkBoxColumn.Name = "Select"
$checkBoxColumn.HeaderText = "Select"
$dataGridView.Columns.Add($checkBoxColumn)

$dataGridView.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{ Name = "Server"; HeaderText = "Server" }))
$dataGridView.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{ Name = "Service Name"; HeaderText = "Service Name" }))
$dataGridView.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{ Name = "Status"; HeaderText = "Status" }))
$dataGridView.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{ Name = "Startup Type"; HeaderText = "Startup Type" }))
$dataGridView.Columns.Add((New-Object System.Windows.Forms.DataGridViewTextBoxColumn -Property @{ Name = "Last Checked"; HeaderText = "Last Checked" }))

$form.Controls.Add($dataGridView)

# Create buttons
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Text = "Start"
$buttonStart.Location = New-Object System.Drawing.Point(10, 370)
$buttonStart.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonStart)

$buttonStop = New-Object System.Windows.Forms.Button
$buttonStop.Text = "Stop"
$buttonStop.Location = New-Object System.Drawing.Point(100, 370)
$buttonStop.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonStop)

$buttonEnable = New-Object System.Windows.Forms.Button
$buttonEnable.Text = "Enable"
$buttonEnable.Location = New-Object System.Drawing.Point(190, 370)
$buttonEnable.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonEnable)

$buttonDisable = New-Object System.Windows.Forms.Button
$buttonDisable.Text = "Disable"
$buttonDisable.Location = New-Object System.Drawing.Point(280, 370)
$buttonDisable.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonDisable)

$buttonAuto = New-Object System.Windows.Forms.Button
$buttonAuto.Text = "Auto"
$buttonAuto.Location = New-Object System.Drawing.Point(370, 370)
$buttonAuto.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonAuto)

$buttonRefresh = New-Object System.Windows.Forms.Button
$buttonRefresh.Text = "Refresh"
$buttonRefresh.Location = New-Object System.Drawing.Point(460, 370)
$buttonRefresh.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonRefresh)

# Create Select All and Deselect All buttons
$buttonSelectAll = New-Object System.Windows.Forms.Button
$buttonSelectAll.Text = "Select All"
$buttonSelectAll.Location = New-Object System.Drawing.Point(10, 400)
$buttonSelectAll.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonSelectAll)

$buttonDeselectAll = New-Object System.Windows.Forms.Button
$buttonDeselectAll.Text = "Deselect All"
$buttonDeselectAll.Location = New-Object System.Drawing.Point(100, 400)
$buttonDeselectAll.Size = New-Object System.Drawing.Size(75, 23)
$form.Controls.Add($buttonDeselectAll)

# Create a label for the admin warning
$labelAdminWarning = New-Object System.Windows.Forms.Label
$labelAdminWarning.Text = "This application requires administrative privileges to function properly."
$labelAdminWarning.ForeColor = [System.Drawing.Color]::Red
$labelAdminWarning.AutoSize = $true
$labelAdminWarning.Location = New-Object System.Drawing.Point(10, 430)
$labelAdminWarning.Visible = $false
$form.Controls.Add($labelAdminWarning)

# Create a TextBox for debugging information
$debugConsole = New-Object System.Windows.Forms.TextBox
$debugConsole.Multiline = $true
$debugConsole.ScrollBars = "Vertical"
$debugConsole.ReadOnly = $true
$debugConsole.Location = New-Object System.Drawing.Point(10, 460)
$debugConsole.Size = New-Object System.Drawing.Size(660, 80)
$form.Controls.Add($debugConsole)

# Load configuration
$config = Load-ConfigFile

# Function to refresh the DataGridView
function Refresh-ServiceList {
    $currentCheckedStates = @{}

    # Save current checked states
    foreach ($row in $dataGridView.Rows) {
        if ($row -and $row.Cells["Select"] -ne $null -and $row.Cells["Service Name"] -ne $null -and $row.Cells["Server"] -ne $null) {
            $serviceName = $row.Cells["Service Name"].Value
            $serverName = $row.Cells["Server"].Value
            if ($serviceName -ne $null -and $serverName -ne $null) {
                $key = "$serverName|$serviceName"
                $currentCheckedStates[$key] = $row.Cells["Select"].Value
            }
        }
    }

    $dataGridView.Rows.Clear()

    # Add data to DataGridView
    foreach ($entry in $config) {
        $status = Get-ServiceStatus -Server $entry.Server -ServiceNames $entry.Services
        foreach ($serviceStatus in $status) {
            $checked = $currentCheckedStates["$($serviceStatus.Server)|$($serviceStatus.Name)"] -eq $true
            $row = $dataGridView.Rows.Add()
            $dataGridView.Rows[$row].Cells["Select"].Value = $checked
            $dataGridView.Rows[$row].Cells["Server"].Value = $serviceStatus.Server
            $dataGridView.Rows[$row].Cells["Service Name"].Value = $serviceStatus.Name
            $dataGridView.Rows[$row].Cells["Status"].Value = $serviceStatus.Status
            $dataGridView.Rows[$row].Cells["Startup Type"].Value = $serviceStatus.StartupType
            $dataGridView.Rows[$row].Cells["Last Checked"].Value = $serviceStatus.LastChecked
        }
    }
}

# Add event handlers
$buttonStart.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        if ($row.Cells["Select"].Value -eq $true) {
            $serverName = $row.Cells["Server"].Value
            $serviceName = $row.Cells["Service Name"].Value
            Invoke-Command -ComputerName $serverName -ScriptBlock {
                param ($serviceName)
                Start-Service -Name $serviceName -ErrorAction SilentlyContinue
            } -ArgumentList $serviceName
        }
    }
})

$buttonStop.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        if ($row.Cells["Select"].Value -eq $true) {
            $serverName = $row.Cells["Server"].Value
            $serviceName = $row.Cells["Service Name"].Value
            Invoke-Command -ComputerName $serverName -ScriptBlock {
                param ($serviceName)
                Stop-Service -Name $serviceName -ErrorAction SilentlyContinue
            } -ArgumentList $serviceName
        }
    }
})

$buttonEnable.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        if ($row.Cells["Select"].Value -eq $true) {
            $serverName = $row.Cells["Server"].Value
            $serviceName = $row.Cells["Service Name"].Value
            Invoke-Command -ComputerName $serverName -ScriptBlock {
                param ($serviceName)
                Set-Service -Name $serviceName -StartupType Automatic -ErrorAction SilentlyContinue
            } -ArgumentList $serviceName
        }
    }
})

$buttonDisable.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        if ($row.Cells["Select"].Value -eq $true) {
            $serverName = $row.Cells["Server"].Value
            $serviceName = $row.Cells["Service Name"].Value
            Invoke-Command -ComputerName $serverName -ScriptBlock {
                param ($serviceName)
                Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
            } -ArgumentList $serviceName
        }
    }
})

$buttonAuto.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        if ($row.Cells["Select"].Value -eq $true) {
            $serverName = $row.Cells["Server"].Value
            $serviceName = $row.Cells["Service Name"].Value
            Invoke-Command -ComputerName $serverName -ScriptBlock {
                param ($serviceName)
                try {
                    $service = Get-Service -Name $serviceName -ErrorAction Stop
                    if ($service.Status -eq "Stopped") {
                        Start-Service -Name $serviceName -ErrorAction SilentlyContinue
                    }
                    Set-Service -Name $serviceName -StartupType Automatic -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "Failed to auto-configure '$serviceName' on server '$serverName'."
                }
            } -ArgumentList $serviceName
        }
    }
})

$buttonRefresh.Add_Click({
    Refresh-ServiceList
})

$buttonSelectAll.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        $row.Cells["Select"].Value = $true
    }
})

$buttonDeselectAll.Add_Click({
    foreach ($row in $dataGridView.Rows) {
        $row.Cells["Select"].Value = $false
    }
})

# Show the form
if ($form -ne $null) {
    if (-Not (Check-AdminPrivileges)) {
        $labelAdminWarning.Visible = $true
    }
    Refresh-ServiceList
    $form.ShowDialog()
} else {
    Write-Host "Failed to create form."
}
