##################################################
# Download the specified archives to /tmp/archives
###################################################
resource "null_resource" "download_software" {

  # This will accept either or all of SSH password, ssh key file and base64 encoded content of private key
  connection {
    host = "${var.server}"
    user = "${var.ssh_user}"
    private_key = "${var.ssh_key_content == "None" ? file(coalesce(var.ssh_key, format("%s/devnull", path.module))) : base64decode(var.ssh_key_content)}"
    password    = "${var.ssh_password}"
  }
    
  # Validate we can do passwordless sudo in case we are not root
  provisioner "remote-exec" {
    inline = [
      "sudo -n echo This will fail unless we have passwordless sudo access"
    ]
  }
  
  # TODO: We could make sure we have prereqs such as curl, unzip, etc

  # JSON dump the contents of sw_archive items
  provisioner "file" {
    content     = "${jsonencode(var.sw_archive)}"
    destination = "/tmp/items-config.yaml"
  }

  # If we want to support other archive locations we can refactor this to be run from a script later
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/archives",
      "cd /tmp/archives ; curl -k -L -u ${var.sw_archive["repouser"]}:${var.sw_archive["repopassword"]} ${var.sw_archive["archive_url"]} -o archive.zip",
      "cd /tmp/archives ; curl -k -L -u ${var.sw_archive["repouser"]}:${var.sw_archive["repopassword"]} ${var.sw_archive["installer_url"]} -o installer.zip",
      "cd /tmp/archives ; curl -k -L -u ${var.sw_archive["repouser"]}:${var.sw_archive["repopassword"]} ${var.sw_archive["installer_xml"]} -o install.xml",
      "cd /tmp/archives ; curl -k -L -u ${var.sw_archive["repouser"]}:${var.sw_archive["repopassword"]} ${var.sw_archive["ibmcreds"]} -o ibmcreds.sec"
    ]
  }
}

##################################################
# Extract archives to installation location 
###################################################
resource "null_resource" "extract_archives" {
  
  depends_on = ["null_resource.download_software"]
  
  connection {
    host = "${var.server}"
    user = "${var.ssh_user}"
    private_key = "${var.ssh_key_content == "None" ? file(coalesce(var.ssh_key, format("%s/devnull", path.module))) : base64decode(var.ssh_key_content)}"
    password    = "${var.ssh_password}"
  }
  
  # Unzip the archives and run the installers
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y unzip",
      "mkdir -p /tmp/installsource ; mkdir -p /tmp/installer",
      "unzip /tmp/archives/archive.zip -d /tmp/installsource",
      "unzip /tmp/archives/installer.zip -d /tmp/installer"
    ]
  }
}


##################################################
# Perform installation
# 1. Install IBM Installation Manager
# 2. Update install.xml with correct installation location (for now always install in users home dir)
# 3. Perform software install
###################################################
resource "null_resource" "install_software" {
  
  depends_on = ["null_resource.extract_archives"]
  
  # This will accept either or all of SSH password, ssh key file and base64 encoded content of private key
  connection {
    host = "${var.server}"
    user = "${var.ssh_user}"
    private_key = "${var.ssh_key_content == "None" ? file(coalesce(var.ssh_key, format("%s/devnull", path.module))) : base64decode(var.ssh_key_content)}"
    password    = "${var.ssh_password}"
  }

  # Run the installers and update install.xml
  provisioner "remote-exec" {
    inline = [
      "cd /tmp/installer ; ./userinstc -acceptLicense",
      "sed -i.bak \"s@USERHOME@$HOME@g\" /tmp/archives/install.xml",
      "cd ~/IBM/InstallationManager/eclipse/tools/ ; ./imcl -acceptLicense -showProgress input /tmp/archives/install.xml -secureStorageFile /tmp/archives/ibmcreds.sec",
      "touch ~/.install_complete"
    ]
  }
}
