resource "local_file" "ansible_inventory" {
    content = templatefile("${path.root}/templates/inventory.tftpl",
        {
            masters-dns = aws_instance.masters.*.private_dns,
            masters-ip  = aws_instance.masters.*.private_ip,
            masters-id  = aws_instance.masters.*.id,
            workers-dns = aws_instance.workers.*.private_dns,
            workers-ip  = aws_instance.workers.*.private_ip,
            workers-id  = aws_instance.workers.*.id
        }
    )
    filename = "${path.root}/inventory"
}

data "local_file" "inventory_file" {
    filename="inventory"
}


resource "local_file" "ansible_vars_file" {
    content = <<-EOF
        master_lb: ${aws_lb.k8_masters_lb.dns_name}
        EOF
    filename = "ansible/ansible_vars_file.yml"
}

# wating for bastion server user data init.
# TODO: Need to switch to signaling based solution instead of waiting.
resource "time_sleep" "wait_for_bastion_init" {
  depends_on = [aws_instance.bastion]
  create_duration = "120s"
}

# copy inventory file to bastion:/home/ubuntu/inventory if file_checksum has been modified
resource "null_resource" "copy_inv_to_bastion" {
  depends_on    = [
    local_file.ansible_inventory,
    time_sleep.wait_for_bastion_init,
    aws_instance.bastion
    ]

  triggers = {
      file_checksum = ("${path.root}/inventory")
  }



  provisioner "file" {
    source  = "${path.root}/inventory"
    destination = "/home/ubuntu/inventory"

    connection {
      type          = "ssh"
      host          = aws_instance.bastion.public_ip
      user          = var.ssh_user
      private_key   = tls_private_key.ssh.private_key_pem
      agent         = false
      insecure      = true
    }
  }
}

resource "null_resource" "copy_ansible_playbooks_to_bastion" {
  depends_on    = [
    null_resource.copy_inv_to_bastion,
    time_sleep.wait_for_bastion_init,
    aws_instance.bastion,
    local_file.ansible_vars_file
    ]

  triggers = {
    dir_sha1    = sha1(join("", [for f in fileset(path.root, "ansible/**") : filesha1(f)]))
  }

  provisioner "file" {
      source = "${path.root}/ansible"
      destination = "/home/ubuntu/ansible/"

      connection {
        type        = "ssh"
        host        = aws_instance.bastion.public_ip
        user        = var.ssh_user
        private_key = tls_private_key.ssh.private_key_pem
        insecure    = true
        agent         = false
      }

  }
}

# calls ansible from bastion to push ansible configuration to all nodes in inventory file (masters and workers)
resource "null_resource" "run_ansible" {
  depends_on = [
    null_resource.copy_inv_to_bastion,
    null_resource.copy_ansible_playbooks_to_bastion,
    aws_instance.masters,
    aws_instance.workers,
    module.vpc,
    aws_instance.bastion,
    time_sleep.wait_for_bastion_init
  ]

  triggers = {
    dir_sha1    = sha1(join("", [for f in fileset(path.root, "ansible/**") : filesha1(f)]))
    file_checksum = ("${path.root}/inventory")

  }

  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent         = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'starting ansible playbooks...'",
      "sleep 60 && ansible-playbook -i /home/ubuntu/inventory /home/ubuntu/ansible/play.yml ",
    ]
  }
}
