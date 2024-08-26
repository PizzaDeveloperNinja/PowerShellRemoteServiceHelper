# Service Helper PowerShell Script

## Overview
The Service Helper is a PowerShell script with a graphical user interface (GUI) designed to help administrators manage Windows services on multiple remote servers. The script reads server and service details from a configuration file (`config.txt`) and displays them in a user-friendly DataGridView interface. Users can start, stop, enable, disable, and refresh services across all listed servers.

## Use Cases
- **Service Management:** Simplify the management of services across multiple servers.
- **Bulk Operations:** Perform bulk operations on services, such as starting or stopping multiple services simultaneously.
- **Status Monitoring:** Easily monitor the status and startup type of services on remote servers.
- **Configuration File:** The script uses a `config.txt` file to define the servers and services to manage, making it flexible and easy to update.

## Features
- **Admin Check:** Verifies if the script is running with local administrative privileges and warns users if it's not. Depending on your use case, these privileges may not be required.
- **Configuration Loading:** Automatically loads server and service details from `config.txt`.
- **Service Status:** Fetches and displays the current status and startup type of services.
- **User Interface:** Provides a simple GUI with checkboxes for selecting services and buttons for various operations.
- **Debug Console:** Includes a console for debugging information, helping users track actions and errors.

## Getting Started
1. **Prepare Configuration:** Create a `config.txt` file with the server names and associated services.
2. **Run Script:** Execute the script with administrative privileges to ensure full functionality.
3. **Manage Services:** Use the GUI to manage the services across your servers.

### Example `config.txt`
```plaintext
server=Server1
services=ServiceA, ServiceB

server=Server2
services=ServiceC, ServiceD
```

## Troubleshooting and Requirements for Remote Servers
Depending on your setup, this script may (and is likely to) run out of the box. If something fails, maybe one of these requirements is not met.

For the remote servers to be managed by the Service Helper PowerShell script, they must meet the following requirements:

1. **PowerShell Remoting Enabled:**
   - PowerShell Remoting must be enabled on the remote servers. This can be done using the `Enable-PSRemoting` cmdlet.
   - Example: Run the following command in an elevated PowerShell session on each remote server:
     ```powershell
     Enable-PSRemoting -Force
     ```

2. **Firewall Configuration:**
   - The firewall on the remote servers must allow incoming connections on the ports used by PowerShell Remoting (default is TCP port 5985 for HTTP and 5986 for HTTPS).
   - Ensure that the necessary firewall rules are in place to allow these connections.

3. **Administrative Credentials:**
   - The user account running the script must have administrative privileges on the remote servers. This is required to manage services and perform other administrative tasks.

4. **WinRM (Windows Remote Management) Service:**
   - The WinRM service must be running on the remote servers. This service is required for PowerShell Remoting.
   - Ensure the service is set to start automatically and is running.
   - Example:
     ```powershell
     Set-Service -Name WinRM -StartupType Automatic
     Start-Service -Name WinRM
     ```

5. **TrustedHosts Configuration (Optional):**
   - If the remote servers are not part of the same domain, you may need to add them to the `TrustedHosts` list on the machine running the script.
   - Example:
     ```powershell
     Set-Item WSMan:\localhost\Client\TrustedHosts -Value "Server1,Server2"
     ```
   - Be cautious when adding hosts to `TrustedHosts` as it reduces the security level.

6. **Remote UAC (User Account Control) Consideration:**
   - On servers running Windows Server with UAC enabled, local accounts with administrative privileges may require additional configuration. You might need to modify the `LocalAccountTokenFilterPolicy` to allow full administrative access.
   - Example:
     ```powershell
     New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord
     ```



