########################################################################################################################
#                                                                                                                      #
#                                  OpenSSH Cookbook           											                                   #
#                                                                                                                      #
#   Language            : Chef/Ruby                                                                                    #
#   Date                : 11/28/2017                                                                                   #
#   Date Last Update    : 11/28/2017                                                                                   #
#   Version             : 1.0                                                                                          #
#   Author              : Arnaud Thalamot                                                                              #
#                                                                                                                      #
########################################################################################################################

require 'chef/resource'

use_inline_resources

def whyrun_supported?
  true
end

action :install do
  converge_by("Create #{@new_resource}") do

    if platform_family?('windows')

      # Download link framework 3.5
      urlopenssh = 'https://client.com/ibm/windows2012R2/osconfig/OpenSSH-Win64.zip'
      # Path of framework 3.5
      pathopenssh = 'C:/Windows/Temp/OpenSSH-Win64.zip'

      Chef::Log.info('Downloading OpenSSH ..................')
      remote_file urlopenssh.to_s do
          source  urlopenssh.to_s
          path  pathopenssh.to_s
          action :create
        end

      Chef::Log.info('Extracting OpenSSH ..................')

      # Extracts the archive
      ruby_block 'extracting-archive' do
        block do
          Chef::Log.info 'extracting-archive'
          command = powershell_out("Add-Type -assembly \"system.io.compression.filesystem\"; [io.compression.zipfile]::ExtractToDirectory('#{pathopenssh}', 'C:/Program Files') | Out-Null")
          Chef::Log.debug command
        end
        action :run
      end

      Chef::Log.info('Installing OpenSSH ..................')
      # Install OpenSSH
      powershell_script 'install-openssh' do
        code <<-EOH
        cd 'C:/Program Files/OpenSSH-Win64/'
        ./install-sshd.ps1
        EOH
      end

      Chef::Log.info('Generating server keys ..................')
      # Generate a set of keys for the server
      powershell_script 'generate-keys' do
        code <<-EOH
        cd 'C:/Program Files/OpenSSH-Win64/'
        ./ssh-keygen.exe -A
        EOH
      end

      Chef::Log.info('Configuring path ..................')
      # Configure the path to include openssh
      powershell_script 'generate-keys' do
        code <<-EOH
        $env:Path='$env:Path;C:\\Program Files\\OpenSSH-Win64'
        EOH
      end

      # SSHD configuration file
      Chef::Log.info('Configuring SSH configuration file..................')
      template 'C:\\Program Files\\OpenSSH-Win64\\sshd_config' do
        source 'sshd_config.erb'
        action :create
      end

      ruby_block 'wait-install' do
        block do
          sleep(30)
        end
        action :create
      end

      Chef::Log.info('Configuring ssh-agent ..................')
      # Start ssh-agent service
      windows_service 'ssh-agent' do
        action :configure_startup
        startup_type :automatic
      end

      Chef::Log.info('Configuring sshd agent ..................')
      # Start sshd service
      windows_service 'sshd' do
        action :configure_startup
        startup_type :automatic
      end
      
      Chef::Log.info('Fixing Key file Permission ..................')
      # Fix ssh Key File Permission
      powershell_script 'fix_keyfile_permission' do
        code <<-EOH
        cd 'C:/Program Files/OpenSSH-Win64/'
        ./FixHostFilePermissions.ps1 -Confirm:$false
        EOH
      end

      Chef::Log.info('Starting ssh-agent ..................')
      # Start ssh-agent service
      windows_service 'ssh-agent' do
        action :start
      end

      Chef::Log.info('Starting sshd agent ..................')
      # Start sshd service
      windows_service 'sshd' do
        action :start
      end

      execute 'set-sshd-expires' do
        command "WMIC USERACCOUNT WHERE Name='sshd' SET PasswordExpires=TRUE"
        action :run
      end
    end
  end
end